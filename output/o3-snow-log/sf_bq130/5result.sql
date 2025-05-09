/* -----------------------------------------------------------
   One single query that
   1) ranks every state by how often it appears in the DAILY TOP-5
      for NEW Covid-19 cases (01-Mar-2020 → 31-May-2020)
   2) finds the 4-th ranked state
   3) lists that state’s TOP-5 counties by the same metric
      (frequency of appearing in the DAILY county-level TOP-5)
   The final SELECT returns the two results in one result set,
   distinguished by a result_type column.
------------------------------------------------------------*/
WITH daily_state AS (                       -- state-level NEW cases
    SELECT
        "date",
        "state_name",
        COALESCE(
            "confirmed_cases"
          - LAG("confirmed_cases")
                OVER (PARTITION BY "state_name" ORDER BY "date"),
            0
        ) AS new_cases
    FROM COVID19_NYT.COVID19_NYT."US_STATES"
    WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
ranked_state AS (                           -- rank states each day
    SELECT
        "date",
        "state_name",
        ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY new_cases DESC) AS rn
    FROM daily_state
),
state_freq AS (                             -- how often each state is in daily TOP-5
    SELECT
        "state_name",
        COUNT(*) AS appearances_in_daily_top5
    FROM ranked_state
    WHERE rn <= 5
    GROUP BY "state_name"
),
target_state AS (                           -- the 4-th most-frequent state
    SELECT "state_name"
    FROM (
        SELECT
            "state_name",
            appearances_in_daily_top5,
            ROW_NUMBER() OVER (ORDER BY appearances_in_daily_top5 DESC) AS pos
        FROM state_freq
    )
    WHERE pos = 4
),
daily_county AS (                           -- county-level NEW cases for that state
    SELECT
        c."date",
        c."county",
        c."county_fips_code",
        COALESCE(
            c."confirmed_cases"
          - LAG(c."confirmed_cases")
                OVER (PARTITION BY c."county_fips_code" ORDER BY c."date"),
            0
        ) AS new_cases
    FROM COVID19_NYT.COVID19_NYT."US_COUNTIES"  c
    JOIN target_state                           t
      ON c."state_name" = t."state_name"
    WHERE c."date" BETWEEN '2020-03-01' AND '2020-05-31'
),
ranked_county AS (                          -- rank counties each day
    SELECT
        "date",
        "county",
        ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY new_cases DESC) AS rn
    FROM daily_county
),
county_freq AS (                            -- frequency a county is in daily TOP-5
    SELECT
        "county",
        COUNT(*) AS appearances_in_daily_top5
    FROM ranked_county
    WHERE rn <= 5
    GROUP BY "county"
    ORDER BY appearances_in_daily_top5 DESC NULLS LAST
    LIMIT 5
)
SELECT
    'STATE_RANKING'                           AS result_type,
    "state_name"                              AS state_name,
    NULL::TEXT                                AS county,
    appearances_in_daily_top5                 AS appearances_in_daily_top5
FROM state_freq

UNION ALL

SELECT
    'COUNTY_RANKING'                          AS result_type,
    (SELECT "state_name" FROM target_state)   AS state_name,
    "county"                                  AS county,
    appearances_in_daily_top5                 AS appearances_in_daily_top5
FROM county_freq

ORDER BY
    result_type,
    appearances_in_daily_top5 DESC NULLS LAST;
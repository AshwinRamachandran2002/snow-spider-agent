/*--------------------------------------------------------------------
  1) Rank states by how often they appear in the DAILY top-5 for NEW
     COVID-19 cases (01-Mar-2020 – 31-May-2020)

  2) Locate the state that finishes 4th in that ranking and, for the
     same time-window, rank its counties by how often they appear in
     the DAILY top-5 for NEW cases.

  The query returns one unified result set with a “result_type” flag:
      • STATE_RANKING                   – every state’s appearance count
      • COUNTY_RANKING_FOR_4TH_STATE    – top-5 counties for the 4th state
--------------------------------------------------------------------*/
WITH state_daily AS (               -- daily NEW cases per state
    SELECT
        "date",
        "state_name",
        "confirmed_cases"
          - LAG("confirmed_cases") OVER (PARTITION BY "state_name"
                                         ORDER BY "date")           AS new_cases
    FROM COVID19_NYT.COVID19_NYT.US_STATES
    WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
state_ranked AS (                   -- pick the five hardest-hit states each day
    SELECT
        "date",
        "state_name",
        new_cases,
        ROW_NUMBER() OVER (PARTITION BY "date"
                           ORDER BY new_cases DESC NULLS LAST)      AS rn
    FROM state_daily
),
daily_state_top5 AS (
    SELECT "state_name"
    FROM   state_ranked
    WHERE  rn <= 5
),
state_appearances AS (              -- how many times each state is in a daily top-5
    SELECT
        "state_name",
        COUNT(*) AS appearances_in_top5
    FROM daily_state_top5
    GROUP BY "state_name"
),
state_rank AS (                     -- overall ranking of states
    SELECT
        "state_name",
        appearances_in_top5,
        DENSE_RANK() OVER (ORDER BY appearances_in_top5 DESC,
                                   "state_name"        ASC)         AS overall_rank
    FROM state_appearances
),
/* ----------  4th-ranked state  ---------- */
fourth_state AS (
    SELECT "state_name"
    FROM   state_rank
    WHERE  overall_rank = 4
),
/* ----------  County-level work for that state ---------- */
county_daily AS (                   -- daily NEW cases per county in 4th state
    SELECT
        "date",
        "county",
        "county_fips_code",
        "state_name",
        "confirmed_cases"
          - LAG("confirmed_cases") OVER (PARTITION BY "county_fips_code"
                                         ORDER BY "date")           AS new_cases
    FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
    WHERE "state_name" IN (SELECT "state_name" FROM fourth_state)
      AND "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
county_ranked AS (                  -- daily top-5 counties inside 4th state
    SELECT
        "date",
        "county",
        new_cases,
        ROW_NUMBER() OVER (PARTITION BY "date"
                           ORDER BY new_cases DESC NULLS LAST)      AS rn
    FROM county_daily
),
daily_county_top5 AS (
    SELECT "county"
    FROM   county_ranked
    WHERE  rn <= 5
),
county_appearances AS (             -- how many times each county is in a daily top-5
    SELECT
        "county",
        COUNT(*) AS appearances_in_top5
    FROM daily_county_top5
    GROUP BY "county"
),
county_top5 AS (                    -- keep only the five most-frequent counties
    SELECT
        "county",
        appearances_in_top5
    FROM county_appearances
    ORDER BY appearances_in_top5 DESC,
             "county"              ASC
    LIMIT 5
)
/* ----------  Final unified result set  ---------- */
SELECT
    'STATE_RANKING' AS result_type,
    "state_name"    AS name,
    appearances_in_top5
FROM state_rank

UNION ALL

SELECT
    'COUNTY_RANKING_FOR_4TH_STATE' AS result_type,
    "county"                       AS name,
    appearances_in_top5
FROM county_top5;
/* ------------------------------------------------------------------
   DAILY NEW-CASE LEADERS (MAR-MAY 2020)
   ‑ Count how often each STATE lands in the daily Top-5
   ‑ Identify the 4th-ranked state
   ‑ For that state, count how often each COUNTY lands in its
     own daily Top-5 list and keep the Top-5 counties
   -----------------------------------------------------------------*/
WITH state_new_cases AS (          -- daily new cases per state
    SELECT
        "date",
        "state_name",
        "confirmed_cases"
          - LAG("confirmed_cases") OVER (PARTITION BY "state_name"
                                         ORDER BY "date")          AS "new_cases"
    FROM COVID19_NYT.COVID19_NYT.US_STATES
    WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
state_daily_top5 AS (              -- Top-5 states each day
    SELECT
        "date",
        "state_name",
        "new_cases",
        ROW_NUMBER() OVER (PARTITION BY "date"
                           ORDER BY "new_cases" DESC NULLS LAST)   AS "rk"
    FROM state_new_cases
    WHERE "new_cases" IS NOT NULL
),
state_top5_counts AS (             -- # appearances per state
    SELECT
        "state_name",
        COUNT(*)                                                       AS "top5_appearances",
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, "state_name")       AS "overall_rank"
    FROM state_daily_top5
    WHERE "rk" <= 5
    GROUP BY "state_name"
),
fourth_state AS (                  -- 4th-ranked state
    SELECT "state_name"
    FROM state_top5_counts
    WHERE "overall_rank" = 4
),
/* -------- COUNTY-LEVEL SECTION (restricted to 4th-ranked state) -------- */
county_new_cases AS (              -- daily new cases per county
    SELECT
        uc."date",
        uc."state_name",
        uc."county",
        uc."confirmed_cases"
          - LAG(uc."confirmed_cases") OVER (PARTITION BY uc."state_name", uc."county"
                                             ORDER BY uc."date")    AS "new_cases"
    FROM COVID19_NYT.COVID19_NYT.US_COUNTIES uc
    WHERE uc."date" BETWEEN '2020-03-01' AND '2020-05-31'
),
county_daily_top5 AS (             -- Top-5 counties each day (within the state)
    SELECT
        c."date",
        c."county",
        ROW_NUMBER() OVER (PARTITION BY c."date"
                           ORDER BY c."new_cases" DESC NULLS LAST)  AS "rk"
    FROM county_new_cases c
    JOIN fourth_state fs
      ON c."state_name" = fs."state_name"
    WHERE c."new_cases" IS NOT NULL
),
county_top5_counts AS (            -- # appearances per county
    SELECT
        "county",
        COUNT(*)  AS "top5_appearances"
    FROM county_daily_top5
    WHERE "rk" <= 5
    GROUP BY "county"
    ORDER BY "top5_appearances" DESC, "county"
    LIMIT 5
)
/* ---------------- SINGLE FINAL RESULT SET ---------------------- */
SELECT
    'STATE'                               AS "level",
    stc."state_name",
    NULL                                   AS "county",
    stc."top5_appearances"                 AS "appearances",
    stc."overall_rank"                     AS "rank_within_level"
FROM state_top5_counts stc

UNION ALL

SELECT
    'COUNTY (4TH-RANKED STATE)'           AS "level",
    fs."state_name"                       AS "state_name",
    ctc."county",
    ctc."top5_appearances"                AS "appearances",
    NULL                                   AS "rank_within_level"
FROM county_top5_counts ctc
CROSS JOIN fourth_state fs

ORDER BY "level", "rank_within_level" NULLS LAST, "appearances" DESC, "county";
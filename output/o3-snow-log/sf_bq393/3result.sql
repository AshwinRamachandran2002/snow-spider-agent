WITH "FILTERED" AS (   -- keep only records up to 10-Sep-2024, bucketed by month
    SELECT 
        "by"                                                   AS "USER_ID",
        DATE_TRUNC('month', TO_TIMESTAMP("time"))              AS "ACTIVITY_MONTH"
    FROM HACKER_NEWS.HACKER_NEWS."FULL"
    WHERE TO_TIMESTAMP("time") < '2024-09-11'                  -- up-to-and-including 10-Sep-2024
      AND "by" IS NOT NULL
), 
"USER_STATS" AS (        -- first / last active month and span length for each user
    SELECT
        "USER_ID",
        MIN("ACTIVITY_MONTH")                                  AS "FIRST_MONTH",
        MAX("ACTIVITY_MONTH")                                  AS "LAST_MONTH",
        COUNT(DISTINCT "ACTIVITY_MONTH")                       AS "ACTIVE_MONTHS",
        DATEDIFF('month', MIN("ACTIVITY_MONTH"), 
                         MAX("ACTIVITY_MONTH")) + 1            AS "TOTAL_SPAN_MONTHS"
    FROM "FILTERED"
    GROUP BY "USER_ID"
), 
"QUALIFIED" AS (         -- users who skipped at least one month and then went silent
    SELECT
        "USER_ID",
        "FIRST_MONTH",
        "LAST_MONTH",
        DATEDIFF('month', "FIRST_MONTH", "LAST_MONTH") + 1     AS "LAST_MONTH_NUMBER"
    FROM "USER_STATS"
    WHERE "TOTAL_SPAN_MONTHS" > "ACTIVE_MONTHS"                                -- gap inside span
      AND "LAST_MONTH" < DATE_TRUNC('month', '2024-09-10'::date)               -- no activity Sep-24
)
SELECT 
    "USER_ID",
    "LAST_MONTH_NUMBER"                                       AS "MONTH_NUMBER"
FROM "QUALIFIED"
ORDER BY "MONTH_NUMBER" DESC NULLS LAST
LIMIT 1;
WITH base AS (
    /* keep events up to 10-Sep-2024 and map each to its month */
    SELECT
        "by"                                                      AS "USER_ID",
        DATE_TRUNC('month', TO_TIMESTAMP("time"))                 AS "ACTIVITY_MONTH"
    FROM HACKER_NEWS.HACKER_NEWS.FULL
    WHERE "by" IS NOT NULL
      AND "time" <= DATE_PART(EPOCH_SECOND,
                              TO_TIMESTAMP_NTZ('2024-09-10 23:59:59'))
),
per_user AS (
    /* first/last month and how many months the user was active */
    SELECT
        "USER_ID",
        MIN("ACTIVITY_MONTH")                        AS "FIRST_MONTH",
        MAX("ACTIVITY_MONTH")                        AS "LAST_MONTH",
        COUNT(DISTINCT "ACTIVITY_MONTH")             AS "ACTIVE_MONTH_CNT"
    FROM base
    GROUP BY "USER_ID"
),
with_gaps AS (
    /* total months in span, missing months, keep only those with gaps */
    SELECT
        "USER_ID",
        DATEDIFF(month, "FIRST_MONTH", "LAST_MONTH") + 1              AS "TOTAL_MONTH_CNT",
        "ACTIVE_MONTH_CNT",
        (DATEDIFF(month, "FIRST_MONTH", "LAST_MONTH") + 1) 
            - "ACTIVE_MONTH_CNT"                                      AS "MISSING_MONTH_CNT"
    FROM per_user
    WHERE (DATEDIFF(month, "FIRST_MONTH", "LAST_MONTH") + 1) 
            - "ACTIVE_MONTH_CNT" > 0
)
SELECT
    "USER_ID",
    "TOTAL_MONTH_CNT"  AS "MONTH_NUMBER"
FROM with_gaps
ORDER BY "TOTAL_MONTH_CNT" DESC NULLS LAST
LIMIT 1;
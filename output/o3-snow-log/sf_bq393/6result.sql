WITH activity_per_month AS (
    SELECT
        "by"                                      AS "USER_ID",
        DATE_TRUNC('month', TO_TIMESTAMP("time")) AS "ACTIVITY_MONTH"
    FROM HACKER_NEWS.HACKER_NEWS.FULL
    WHERE "by"   IS NOT NULL
      AND "time" IS NOT NULL
      AND TO_TIMESTAMP("time") <= TO_TIMESTAMP('2024-09-10 23:59:59')
), user_span AS (
    SELECT
        "USER_ID",
        MIN("ACTIVITY_MONTH")                          AS "FIRST_MONTH",
        MAX("ACTIVITY_MONTH")                          AS "LAST_MONTH",
        COUNT(DISTINCT "ACTIVITY_MONTH")               AS "ACTIVE_MONTHS_CNT"
    FROM activity_per_month
    GROUP BY "USER_ID"
), user_with_gaps AS (
    SELECT
        "USER_ID",
        DATEDIFF('month', "FIRST_MONTH", "LAST_MONTH") + 1  AS "EXPECTED_MONTHS_CNT",
        "ACTIVE_MONTHS_CNT"
    FROM user_span
    WHERE "ACTIVE_MONTHS_CNT" < DATEDIFF('month', "FIRST_MONTH", "LAST_MONTH") + 1
), ranked AS (
    SELECT
        "USER_ID",
        "EXPECTED_MONTHS_CNT"                           AS "MONTH_NUMBER",
        ROW_NUMBER() OVER (ORDER BY "EXPECTED_MONTHS_CNT" DESC NULLS LAST, "USER_ID") AS "RN"
    FROM user_with_gaps
)
SELECT
    "USER_ID",
    "MONTH_NUMBER"
FROM ranked
WHERE "RN" = 1;
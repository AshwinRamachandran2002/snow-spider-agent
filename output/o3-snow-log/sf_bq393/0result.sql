WITH activities AS (  -- all activity up to 10-Sep-2024
    SELECT
        "by"                                                AS "USER",
        DATE_TRUNC('month', TO_TIMESTAMP("time"))           AS "ACTIVITY_MONTH"
    FROM HACKER_NEWS.HACKER_NEWS.FULL
    WHERE "by" IS NOT NULL
      AND TO_TIMESTAMP("time") <= '2024-09-10'          -- cut-off date (inclusive)
),                                                       
user_months AS (        -- distinct months per user
    SELECT DISTINCT
        "USER",
        "ACTIVITY_MONTH"
    FROM activities
),                                                         
user_bounds AS (        -- first & last month plus span length
    SELECT
        "USER",
        MIN("ACTIVITY_MONTH")                                AS "FIRST_MONTH",
        MAX("ACTIVITY_MONTH")                                AS "LAST_MONTH",
        DATEDIFF(month, MIN("ACTIVITY_MONTH"), MAX("ACTIVITY_MONTH"))   AS "SPAN_MONTHS",
        COUNT(*)                                             AS "ACTIVE_MONTHS"
    FROM user_months
    GROUP BY "USER"
),                                                         
users_with_gaps AS (    -- user must have at least one missing month inside span
    SELECT *
    FROM user_bounds
    WHERE "ACTIVE_MONTHS" < "SPAN_MONTHS" + 1
),                                                         
last_index AS (         -- month index (starting at 1) of last recorded activity
    SELECT
        "USER",
        "SPAN_MONTHS" + 1                                   AS "LAST_ACTIVE_MONTH_NUM"
    FROM users_with_gaps
),                                                         
ranked AS (             -- choose the user with the highest month number
    SELECT
        "USER",
        "LAST_ACTIVE_MONTH_NUM",
        ROW_NUMBER() OVER (ORDER BY "LAST_ACTIVE_MONTH_NUM" DESC, "USER") AS "RN"
    FROM last_index
)                                                          
SELECT
    "USER"        AS "USER_ID",
    "LAST_ACTIVE_MONTH_NUM" AS "MONTH_NUMBER"
FROM ranked
WHERE "RN" = 1;
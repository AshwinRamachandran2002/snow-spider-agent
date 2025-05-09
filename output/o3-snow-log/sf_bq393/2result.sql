WITH activity AS (   -- keep only records up to 10-Sep-2024 and map each to its year-month
    SELECT
        "by"                                                     AS user_id,
        DATE_TRUNC('month', TO_TIMESTAMP("time"))                AS activity_month
    FROM HACKER_NEWS.HACKER_NEWS.FULL
    WHERE "time" <= DATE_PART(EPOCH_SECOND, TO_TIMESTAMP_NTZ('2024-09-10 23:59:59'))
      AND "by" IS NOT NULL
),
user_stats AS (      -- first month, last month and #active months for every user
    SELECT
        user_id,
        MIN(activity_month)                                      AS first_month,
        MAX(activity_month)                                      AS last_month,
        COUNT(DISTINCT activity_month)                           AS active_months
    FROM activity
    GROUP BY user_id
),
calc AS (            -- total span length in months (inclusive)
    SELECT
        user_id,
        DATEDIFF('month', first_month, last_month) + 1           AS month_span,   -- 1 = include first month
        active_months
    FROM user_stats
),
candidates AS (      -- want users who missed at least one month inside their span
    SELECT
        user_id,
        month_span
    FROM calc
    WHERE month_span > active_months
),
ranked AS (          -- pick the user with the largest month number
    SELECT
        user_id,
        month_span,
        ROW_NUMBER() OVER (ORDER BY month_span DESC NULLS LAST, user_id) AS rn
    FROM candidates
)
SELECT
    user_id,
    month_span AS month_number   -- month number counted from the user's first active month
FROM ranked
WHERE rn = 1;
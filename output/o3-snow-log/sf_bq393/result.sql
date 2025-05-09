WITH activity AS (
    /* keep only records up to (and including) 10-Sep-2024 */
    SELECT
        "by"                                                     AS user_id,
        DATE_TRUNC('month', TO_TIMESTAMP("time"))                AS activity_month
    FROM HACKER_NEWS.HACKER_NEWS.FULL
    WHERE TO_TIMESTAMP("time") < '2024-09-11'      -- 10-Sep-2024 23:59:59
      AND "by" IS NOT NULL
),                                   
user_span AS (
    /* span statistics for every user */
    SELECT
        user_id,
        MIN(activity_month)                       AS first_month,
        MAX(activity_month)                       AS last_month,
        COUNT(DISTINCT activity_month)            AS active_months
    FROM activity
    GROUP BY user_id
),                                   
gapped_users AS (
    /* users who missed at least one month inside their span */
    SELECT
        user_id,
        DATEDIFF(month, first_month, last_month) + 1  AS month_number,   -- 1-based index of last active month
        active_months
    FROM user_span
    WHERE DATEDIFF(month, first_month, last_month) + 1 > active_months   -- at least one gap
)
SELECT
    user_id,
    month_number
FROM gapped_users
ORDER BY month_number DESC NULLS LAST, user_id
LIMIT 1;
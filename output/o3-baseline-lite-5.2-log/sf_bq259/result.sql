WITH orders_filtered AS (      -- all completed purchases up to 2022‑12‑31
    SELECT
        "user_id",
        TO_TIMESTAMP_NTZ("created_at" / 1000000) AS order_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" <> 'Cancelled'
      AND TO_TIMESTAMP_NTZ("created_at" / 1000000) < '2023-01-01'
),
first_purchase AS (            -- month of each user’s very first purchase
    SELECT
        "user_id",
        DATE_TRUNC('month', MIN(order_ts)) AS cohort_month
    FROM orders_filtered
    GROUP BY "user_id"
),
user_orders_with_offset AS (   -- month offset (0‑3) from the first purchase
    SELECT
        o."user_id",
        f.cohort_month,
        DATEDIFF(
            'month',
            f.cohort_month,
            DATE_TRUNC('month', o.order_ts)
        ) AS month_offset
    FROM orders_filtered o
    JOIN first_purchase  f ON o."user_id" = f."user_id"
    WHERE DATEDIFF(
            'month',
            f.cohort_month,
            DATE_TRUNC('month', o.order_ts)
          ) BETWEEN 0 AND 3
),
user_month_flags AS (          -- did the user buy in each of the first 4 months?
    SELECT
        "user_id",
        cohort_month,
        MAX(CASE WHEN month_offset = 0 THEN 1 ELSE 0 END) AS first_month,
        MAX(CASE WHEN month_offset = 1 THEN 1 ELSE 0 END) AS second_month,
        MAX(CASE WHEN month_offset = 2 THEN 1 ELSE 0 END) AS third_month,
        MAX(CASE WHEN month_offset = 3 THEN 1 ELSE 0 END) AS fourth_month
    FROM user_orders_with_offset
    GROUP BY "user_id", cohort_month
),
cohort_stats AS (              -- totals and counts per cohort
    SELECT
        cohort_month,
        COUNT(*)                        AS total_users,
        SUM(first_month)   AS users_first_month,
        SUM(second_month)  AS users_second_month,
        SUM(third_month)   AS users_third_month,
        SUM(fourth_month)  AS users_fourth_month
    FROM user_month_flags
    GROUP BY cohort_month
)
SELECT
    cohort_month,
    ROUND(users_first_month  * 100.0 / total_users, 4) AS pct_first_month,
    ROUND(users_second_month * 100.0 / total_users, 4) AS pct_second_month,
    ROUND(users_third_month  * 100.0 / total_users, 4) AS pct_third_month,
    ROUND(users_fourth_month * 100.0 / total_users, 4) AS pct_fourth_month
FROM cohort_stats
ORDER BY cohort_month;
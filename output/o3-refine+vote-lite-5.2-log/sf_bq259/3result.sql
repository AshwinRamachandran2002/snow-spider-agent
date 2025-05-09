WITH orders_filtered AS (   -- all purchases (non‑cancelled) up to 2022‑12‑31
    SELECT
        "user_id",
        DATE_TRUNC('month', TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)))   AS order_month
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"
    WHERE "status" <> 'Cancelled'
      AND TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) < DATE '2023-01-01'
      AND "user_id" IS NOT NULL
),

first_purchase AS (        -- cohort (first‑purchase month) of every user
    SELECT
        "user_id",
        MIN(order_month) AS cohort_month
    FROM orders_filtered
    GROUP BY "user_id"
),

orders_with_cohort AS (    -- month index 1‑4 for every subsequent purchase
    SELECT
        o."user_id",
        f.cohort_month,
        DATEDIFF('month', f.cohort_month, o.order_month) + 1 AS month_number   -- 1 = first month
    FROM orders_filtered o
    JOIN first_purchase  f ON f."user_id" = o."user_id"
    WHERE DATEDIFF('month', f.cohort_month, o.order_month) BETWEEN 0 AND 3     -- keep months 1‑4
),

cohort_sizes AS (          -- total users in every cohort
    SELECT cohort_month,
           COUNT(DISTINCT "user_id") AS total_users
    FROM first_purchase
    GROUP BY cohort_month
),

month_user_counts AS (     -- users purchasing in each month_number
    SELECT cohort_month,
           month_number,
           COUNT(DISTINCT "user_id") AS users_with_purchase
    FROM orders_with_cohort
    GROUP BY cohort_month, month_number
)

SELECT
    c.cohort_month,
    ROUND(100.0 * COALESCE(m1.users_with_purchase,0) / c.total_users, 4) AS pct_month1,   -- month of 1st purchase
    ROUND(100.0 * COALESCE(m2.users_with_purchase,0) / c.total_users, 4) AS pct_month2,   -- 2nd month
    ROUND(100.0 * COALESCE(m3.users_with_purchase,0) / c.total_users, 4) AS pct_month3,   -- 3rd month
    ROUND(100.0 * COALESCE(m4.users_with_purchase,0) / c.total_users, 4) AS pct_month4    -- 4th month
FROM cohort_sizes           c
LEFT JOIN (SELECT * FROM month_user_counts WHERE month_number = 1) m1 USING (cohort_month)
LEFT JOIN (SELECT * FROM month_user_counts WHERE month_number = 2) m2 USING (cohort_month)
LEFT JOIN (SELECT * FROM month_user_counts WHERE month_number = 3) m3 USING (cohort_month)
LEFT JOIN (SELECT * FROM month_user_counts WHERE month_number = 4) m4 USING (cohort_month)
ORDER BY c.cohort_month;
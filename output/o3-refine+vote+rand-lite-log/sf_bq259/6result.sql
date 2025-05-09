WITH complete_orders AS (                 -- all purchases made up to 31‑Dec‑2022
    SELECT
        "user_id",
        TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) AS order_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "status" = 'Complete'
      AND TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) < '2023-01-01'
      AND "user_id" IS NOT NULL
),                                          -- first purchase month (cohort) per user
first_purchase AS (
    SELECT
        "user_id",
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM complete_orders
    GROUP BY "user_id"
),                                          -- every purchase mapped to offset (0‑3)
orders_with_offset AS (
    SELECT
        o."user_id",
        fp.cohort_month,
        DATE_TRUNC('month', o.order_date) AS order_month,
        DATEDIFF('month',
                 fp.cohort_month,
                 DATE_TRUNC('month', o.order_date))         AS month_number         -- 0 = first month
    FROM complete_orders o
    JOIN first_purchase fp
          ON o."user_id" = fp."user_id"
    WHERE DATEDIFF('month',
                   fp.cohort_month,
                   DATE_TRUNC('month', o.order_date)) BETWEEN 0 AND 3
),                                          -- distinct users who bought in each offset
users_per_offset AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT "user_id") AS users_in_period
    FROM orders_with_offset
    GROUP BY cohort_month, month_number
),                                          -- size of every cohort
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT "user_id") AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
),                                          -- percentage calculation
retention AS (
    SELECT
        u.cohort_month,
        u.month_number,
        (u.users_in_period * 100.0) / c.cohort_size AS pct_users
    FROM users_per_offset u
    JOIN cohort_sizes   c
          ON u.cohort_month = c.cohort_month
)
SELECT
    cohort_month                                              AS "FIRST_PURCHASE_MONTH",
    ROUND(MAX(CASE WHEN month_number = 0 THEN pct_users END),4) AS "MONTH_1_PCT",
    ROUND(MAX(CASE WHEN month_number = 1 THEN pct_users END),4) AS "MONTH_2_PCT",
    ROUND(MAX(CASE WHEN month_number = 2 THEN pct_users END),4) AS "MONTH_3_PCT",
    ROUND(MAX(CASE WHEN month_number = 3 THEN pct_users END),4) AS "MONTH_4_PCT"
FROM retention
GROUP BY cohort_month
ORDER BY cohort_month;
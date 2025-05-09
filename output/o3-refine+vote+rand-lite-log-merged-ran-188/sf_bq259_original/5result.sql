WITH orders_filtered AS (      -- all non‑cancelled orders up to 31‑Dec‑2022
    SELECT
        "user_id",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at" / 1000000)) AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "status" <> 'Cancelled'
      AND TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) < '2023-01-01'
),

first_purchases AS (           -- month of each user’s first purchase
    SELECT
        "user_id",
        MIN(order_month) AS cohort_month
    FROM orders_filtered
    GROUP BY "user_id"
),

user_orders AS (               -- month index (1‑4) of every subsequent purchase
    SELECT
        fp.cohort_month,
        o."user_id",
        DATEDIFF('month', fp.cohort_month, o.order_month) + 1 AS month_number
    FROM orders_filtered AS o
    JOIN first_purchases  fp  ON fp."user_id" = o."user_id"
    WHERE DATEDIFF('month', fp.cohort_month, o.order_month) BETWEEN 0 AND 3
),

cohorts AS (                   -- size of every cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT "user_id") AS cohort_size
    FROM first_purchases
    GROUP BY cohort_month
),

retention AS (                 -- how many users bought in months 1‑4
    SELECT
        cohort_month,
        COUNT(DISTINCT CASE WHEN month_number = 1 THEN "user_id" END) AS users_m1,
        COUNT(DISTINCT CASE WHEN month_number = 2 THEN "user_id" END) AS users_m2,
        COUNT(DISTINCT CASE WHEN month_number = 3 THEN "user_id" END) AS users_m3,
        COUNT(DISTINCT CASE WHEN month_number = 4 THEN "user_id" END) AS users_m4
    FROM user_orders
    GROUP BY cohort_month
)

SELECT
    r.cohort_month                          AS "COHORT_MONTH",
    ROUND(r.users_m1 * 100.0 / c.cohort_size, 2) AS "PCT_MONTH_1",
    ROUND(r.users_m2 * 100.0 / c.cohort_size, 2) AS "PCT_MONTH_2",
    ROUND(r.users_m3 * 100.0 / c.cohort_size, 2) AS "PCT_MONTH_3",
    ROUND(r.users_m4 * 100.0 / c.cohort_size, 2) AS "PCT_MONTH_4"
FROM retention r
JOIN cohorts  c  ON r.cohort_month = c.cohort_month
ORDER BY r.cohort_month;
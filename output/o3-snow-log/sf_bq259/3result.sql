/*  Cohort-based retention up to, and including, the 4th month
    (where month 1 = month of first purchase)
    for all users whose first purchase occurred on or before
    31-Dec-2022.                                             */

WITH orders_2022 AS (      -- all orders placed on/before 31-Dec-2022
    SELECT
        "user_id",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at"/1e6)) AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "created_at" IS NOT NULL
      AND TO_TIMESTAMP_NTZ("created_at"/1e6) < '2023-01-01'
),
cohort AS (                -- first-purchase (cohort) month for every user
    SELECT
        "user_id",
        MIN(order_month) AS cohort_month
    FROM orders_2022
    GROUP BY "user_id"
),
user_orders AS (           -- months-since-first-purchase (0-3) for every order
    SELECT
        o."user_id",
        c.cohort_month,
        o.order_month,
        DATEDIFF('month', c.cohort_month, o.order_month) AS month_offset
    FROM orders_2022 o
    JOIN cohort c
      ON o."user_id" = c."user_id"
    WHERE DATEDIFF('month', c.cohort_month, o.order_month) BETWEEN 0 AND 3
),
cohort_sizes AS (          -- size of each cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT "user_id") AS cohort_size
    FROM cohort
    GROUP BY cohort_month
),
retention AS (             -- distinct users ordering in months 0-3
    SELECT
        cohort_month,
        COUNT(DISTINCT CASE WHEN month_offset = 0 THEN "user_id" END) AS m1_users,
        COUNT(DISTINCT CASE WHEN month_offset = 1 THEN "user_id" END) AS m2_users,
        COUNT(DISTINCT CASE WHEN month_offset = 2 THEN "user_id" END) AS m3_users,
        COUNT(DISTINCT CASE WHEN month_offset = 3 THEN "user_id" END) AS m4_users
    FROM user_orders
    GROUP BY cohort_month
)
SELECT
    r.cohort_month                                    AS first_purchase_month,
    ROUND(r.m1_users * 100.0 / cs.cohort_size, 4)     AS first_month_pct,
    ROUND(r.m2_users * 100.0 / cs.cohort_size, 4)     AS second_month_pct,
    ROUND(r.m3_users * 100.0 / cs.cohort_size, 4)     AS third_month_pct,
    ROUND(r.m4_users * 100.0 / cs.cohort_size, 4)     AS fourth_month_pct
FROM retention r
JOIN cohort_sizes cs
  ON r.cohort_month = cs.cohort_month
ORDER BY first_purchase_month NULLS LAST;
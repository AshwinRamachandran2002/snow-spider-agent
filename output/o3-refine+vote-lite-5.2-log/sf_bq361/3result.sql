WITH orders AS (
    SELECT
        "user_id",
        TO_TIMESTAMP("created_at" / 1000000) AS order_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "user_id" IS NOT NULL
),
first_orders AS (                        -- first‐ever purchase for every user
    SELECT
        "user_id",
        MIN(order_ts) AS first_order_ts
    FROM orders
    GROUP BY "user_id"
),
january_2020_cohort AS (                 -- users whose very first order was in Jan‑2020
    SELECT "user_id"
    FROM first_orders
    WHERE DATE_TRUNC('month', first_order_ts) = TO_DATE('2020-01-01')
),
subsequent_orders_2020 AS (              -- later 2020 orders by those users
    SELECT
        o."user_id",
        DATE_TRUNC('month', o.order_ts) AS order_month
    FROM orders o
    JOIN january_2020_cohort c
      ON o."user_id" = c."user_id"
    WHERE DATE_TRUNC('year', o.order_ts) = TO_DATE('2020-01-01')
      AND DATE_TRUNC('month', o.order_ts) > TO_DATE('2020-01-01')
),
returning_by_month AS (                  -- how many of them bought again in each month
    SELECT
        order_month,
        COUNT(DISTINCT "user_id") AS returning_users
    FROM subsequent_orders_2020
    GROUP BY order_month
),
cohort_size AS (                         -- total size of the Jan‑2020 cohort
    SELECT COUNT(DISTINCT "user_id") AS cohort_users
    FROM january_2020_cohort
)
SELECT
    TO_CHAR(order_month, 'YYYY-MM')     AS "month",
    returning_users,
    cohort_users,
    ROUND(returning_users * 1.0 / cohort_users, 4) AS "proportion_returned"
FROM returning_by_month
CROSS JOIN cohort_size
ORDER BY order_month;
/*  Proportion of January‑2020 first‑time purchasers who bought again
    in each subsequent month of 2020                                       */

WITH orders AS (    -- all orders with a readable timestamp
    SELECT
        "user_id",
        TO_TIMESTAMP_NTZ("created_at" / 1000000) AS order_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "created_at" IS NOT NULL
),

first_purchase AS ( -- first‑ever order for every user
    SELECT
        "user_id",
        MIN(order_ts) AS first_order_ts
    FROM orders
    GROUP BY "user_id"
),

january_2020_cohort AS (   -- users whose very first order was in Jan‑2020
    SELECT "user_id"
    FROM first_purchase
    WHERE DATE_TRUNC('month', first_order_ts) = '2020-01-01'::DATE
),

orders_2020 AS (   -- later 2020 orders placed by those cohort users
    SELECT
        o."user_id",
        DATE_TRUNC('month', o.order_ts)::DATE AS order_month
    FROM orders o
    WHERE o.order_ts BETWEEN '2020-02-01'::DATE AND '2020-12-31'::DATE
      AND o."user_id" IN (SELECT "user_id" FROM january_2020_cohort)
),

cohort_activity AS (   -- distinct cohort users active each month
    SELECT
        order_month,
        COUNT(DISTINCT "user_id") AS active_users
    FROM orders_2020
    GROUP BY order_month
),

cohort_size AS (       -- size of the January cohort
    SELECT COUNT(DISTINCT "user_id") AS total_users
    FROM january_2020_cohort
),

calendar_months AS (   -- list of Feb‑2020 .. Dec‑2020
    SELECT DATEADD(month, seq4(), '2020-02-01'::DATE) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 11))
)

SELECT
    TO_CHAR(cm.month_start, 'YYYY-MM')                         AS month,
    COALESCE(ROUND(ca.active_users / cs.total_users, 4), 0)    AS proportion_returned
FROM calendar_months  cm
LEFT JOIN cohort_activity ca  ON cm.month_start = ca.order_month
CROSS JOIN cohort_size cs
ORDER BY cm.month_start;
/*  Cohort-based monthly retention (up to Dec-2022)              */
/*  – cohort = month of a user’s first completed order           */
/*  – percentages for months 0-3 (0 = month of first purchase)   */

WITH orders_2022 AS (          -- all PURCHASES up to 2022-12-31
    SELECT
        "user_id",
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ("created_at" / 1000000)
                  )::date              AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "user_id" IS NOT NULL
      AND "status" <> 'Cancelled'      -- keep only real purchases
      AND TO_TIMESTAMP_NTZ("created_at" / 1000000) < '2023-01-01'
), 

cohorts AS (                  -- first-purchase month for every user
    SELECT
        "user_id",
        MIN(order_month) AS cohort_month
    FROM orders_2022
    GROUP BY "user_id"
),

user_orders AS (              -- month offset (0-3) for every order
    SELECT
        o."user_id",
        c.cohort_month,
        o.order_month,
        DATEDIFF('month', c.cohort_month, o.order_month) AS month_offset
    FROM orders_2022 o
    JOIN cohorts c
      ON o."user_id" = c."user_id"
    WHERE DATEDIFF('month', c.cohort_month, o.order_month) BETWEEN 0 AND 3
),

retention AS (                -- users active in each offset month
    SELECT
        cohort_month,
        month_offset,
        COUNT(DISTINCT "user_id") AS users_in_month
    FROM user_orders
    GROUP BY cohort_month, month_offset
),

cohort_sizes AS (             -- size of every cohort (month 0)
    SELECT
        cohort_month,
        users_in_month AS cohort_size
    FROM retention
    WHERE month_offset = 0
),

retention_pct AS (            -- percentage of cohort active
    SELECT
        r.cohort_month,
        r.month_offset,
        ROUND( r.users_in_month * 100.0 / cs.cohort_size , 4) AS pct_users
    FROM retention r
    JOIN cohort_sizes cs
      ON r.cohort_month = cs.cohort_month
)

SELECT
    cohort_month                                             AS cohort_month,
    MAX(CASE WHEN month_offset = 0 THEN pct_users END)       AS month_0_pct,
    MAX(CASE WHEN month_offset = 1 THEN pct_users END)       AS month_1_pct,
    MAX(CASE WHEN month_offset = 2 THEN pct_users END)       AS month_2_pct,
    MAX(CASE WHEN month_offset = 3 THEN pct_users END)       AS month_3_pct
FROM retention_pct
GROUP BY cohort_month
ORDER BY cohort_month;
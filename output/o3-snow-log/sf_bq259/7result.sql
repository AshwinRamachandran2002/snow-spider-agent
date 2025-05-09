/*   Cohort-based retention (up to, and including, Dec-2022)
     ------------------------------------------------------
     – Cohort     : month of a user’s first completed order
     – Retention  : % of those users that purchase again in
                    the 1st, 2nd, 3rd & 4th cohort months   */

WITH orders_filtered AS (         -- completed orders up to 31-Dec-2022
    SELECT
        "user_id",
        TO_TIMESTAMP_NTZ("created_at"/1000000) AS order_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" = 'Complete'
      AND TO_TIMESTAMP_NTZ("created_at"/1000000) < '2023-01-01'::timestamp_ntz
      AND "user_id" IS NOT NULL
),

cohort AS (                       -- each user’s first-purchase month
    SELECT
        "user_id",
        DATE_TRUNC('month', MIN(order_ts)) AS cohort_month
    FROM orders_filtered
    GROUP BY "user_id"
),

orders_with_cohort AS (           -- orders mapped to cohort & month index
    SELECT
        o."user_id",
        c.cohort_month,
        DATE_TRUNC('month', o.order_ts)                           AS order_month,
        DATEDIFF('month', c.cohort_month, DATE_TRUNC('month', o.order_ts))
                                                                    AS month_index
    FROM orders_filtered o
    JOIN cohort          c ON o."user_id" = c."user_id"
    WHERE DATEDIFF('month', c.cohort_month, DATE_TRUNC('month', o.order_ts))
          BETWEEN 0 AND 3         -- keep only months 0-3 (4 months total)
),

cohort_size AS (                  -- number of users in each cohort
    SELECT cohort_month,
           COUNT(DISTINCT "user_id") AS users_in_cohort
    FROM cohort
    GROUP BY cohort_month
),

period_users AS (                 -- users purchasing in each period
    SELECT cohort_month,
           month_index,
           COUNT(DISTINCT "user_id") AS users_in_period
    FROM orders_with_cohort
    GROUP BY cohort_month, month_index
),

retention AS (                    -- percentage calculations
    SELECT
        p.cohort_month,
        p.month_index,
        ROUND(p.users_in_period * 100.0 / s.users_in_cohort, 4) AS pct_users
    FROM period_users p
    JOIN cohort_size  s USING (cohort_month)
)

SELECT
    cohort_month,
    MAX(CASE WHEN month_index = 0 THEN pct_users END) AS first_month_pct,
    MAX(CASE WHEN month_index = 1 THEN pct_users END) AS second_month_pct,
    MAX(CASE WHEN month_index = 2 THEN pct_users END) AS third_month_pct,
    MAX(CASE WHEN month_index = 3 THEN pct_users END) AS fourth_month_pct
FROM retention
GROUP BY cohort_month
ORDER BY cohort_month;
/*  Cohort: users whose very first purchase happened in January‑2020
    Metric : for every later month in 2020, share of those users that bought again   */

WITH base_orders AS (   -- keep only non‑cancelled orders, convert date
    SELECT
        "user_id",
        TO_DATE(TO_TIMESTAMP("created_at" / 1000000))            AS order_date    -- micro‑seconds → date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "status" <> 'Cancelled'
      AND "user_id" IS NOT NULL
),

first_purchase AS (     -- first purchase date for every shopper
    SELECT
        "user_id",
        MIN(order_date)                                        AS first_order_date
    FROM base_orders
    GROUP BY "user_id"
),

jan2020_cohort AS (     -- the cohort we analyse
    SELECT "user_id"
    FROM first_purchase
    WHERE first_order_date >= '2020-01-01'
      AND first_order_date <  '2020-02-01'
),

repeat_orders_2020 AS ( -- cohort members’ orders after January‑2020
    SELECT
        bo."user_id",
        DATE_TRUNC('month', bo.order_date)                     AS order_month
    FROM base_orders  bo
    JOIN jan2020_cohort jc  ON jc."user_id" = bo."user_id"
    WHERE bo.order_date >= '2020-02-01'        -- only months AFTER the cohort month
      AND bo.order_date <  '2021-01-01'
    GROUP BY bo."user_id", DATE_TRUNC('month', bo.order_date)
),

monthly_retention AS (  -- number of cohort users that returned each month
    SELECT
        order_month,
        COUNT(DISTINCT "user_id")                              AS returned_users
    FROM repeat_orders_2020
    GROUP BY order_month
),

cohort_size AS (
    SELECT COUNT(*) AS cohort_users FROM jan2020_cohort
)

SELECT
    TO_CHAR(order_month, 'YYYY-MM')                            AS month,
    returned_users,
    cohort_users,
    ROUND(returned_users::FLOAT / cohort_users, 4)             AS retention_rate
FROM monthly_retention, cohort_size
ORDER BY order_month;
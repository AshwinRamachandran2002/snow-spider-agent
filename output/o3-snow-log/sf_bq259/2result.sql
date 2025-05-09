/*  Cohort-retention (first 4 months) of purchasing users up to 31-Dec-2022  */

WITH orders_filtered AS (        -- only real purchases before 2023
    SELECT
        "user_id",
        TO_DATE( TO_TIMESTAMP( "created_at" / 1000000 ) )       AS order_date
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "created_at" < 1672444800000000                       -- 2023-01-01 in µs
      AND "user_id"  IS NOT NULL
      AND "status"  <> 'Cancelled'                             -- exclude non-purchases
), 

orders_month AS (               -- one row per user & purchase month
    SELECT
        "user_id",
        DATE_TRUNC('month', order_date) AS order_month
    FROM orders_filtered
    GROUP BY "user_id", order_month
),

first_purchase AS (             -- first purchase month (cohort) per user
    SELECT
        "user_id",
        MIN(order_month) AS first_order_month
    FROM orders_month
    GROUP BY "user_id"
),

user_orders_relative AS (       -- months since first purchase (0-3)
    SELECT
        om."user_id",
        fp.first_order_month,
        om.order_month,
        DATEDIFF('month', fp.first_order_month, om.order_month) AS months_since_first
    FROM orders_month            AS om
    JOIN first_purchase          AS fp
      ON om."user_id" = fp."user_id"
    WHERE DATEDIFF('month', fp.first_order_month, om.order_month) BETWEEN 0 AND 3
),

cohort_sizes AS (               -- size of each cohort
    SELECT
        first_order_month AS cohort_month,
        COUNT(DISTINCT "user_id") AS cohort_users
    FROM first_purchase
    GROUP BY first_order_month
),

cohort_activity AS (            -- active users by cohort & month-index
    SELECT
        first_order_month AS cohort_month,
        months_since_first,
        COUNT(DISTINCT "user_id") AS active_users
    FROM user_orders_relative
    GROUP BY first_order_month, months_since_first
)

/*  Final retention table -------------------------------------------------- */
SELECT
    cs.cohort_month,
    ROUND(100.0 * COALESCE(MAX(CASE WHEN ca.months_since_first = 0 THEN ca.active_users END),0) / cs.cohort_users ,4) AS pct_month1,
    ROUND(100.0 * COALESCE(MAX(CASE WHEN ca.months_since_first = 1 THEN ca.active_users END),0) / cs.cohort_users ,4) AS pct_month2,
    ROUND(100.0 * COALESCE(MAX(CASE WHEN ca.months_since_first = 2 THEN ca.active_users END),0) / cs.cohort_users ,4) AS pct_month3,
    ROUND(100.0 * COALESCE(MAX(CASE WHEN ca.months_since_first = 3 THEN ca.active_users END),0) / cs.cohort_users ,4) AS pct_month4
FROM          cohort_sizes   AS cs
LEFT JOIN     cohort_activity AS ca
       ON cs.cohort_month = ca.cohort_month
GROUP BY cs.cohort_month, cs.cohort_users
ORDER BY cs.cohort_month NULLS LAST;
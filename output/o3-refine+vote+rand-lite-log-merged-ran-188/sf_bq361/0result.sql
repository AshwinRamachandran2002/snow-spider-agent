WITH first_purchase AS (
    -- First purchase timestamp for every shopper
    SELECT
        "user_id",
        MIN(TO_TIMESTAMP_NTZ("created_at" / 1000000)) AS "first_purchase_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
),
jan2020_cohort AS (
    -- Users whose very first order was in January-2020
    SELECT "user_id"
    FROM   first_purchase
    WHERE  "first_purchase_ts" BETWEEN '2020-01-01' AND '2020-01-31 23:59:59'
),
cohort_size AS (
    -- Total number of cohort users
    SELECT COUNT(DISTINCT "user_id") AS "total_users"
    FROM   jan2020_cohort
),
orders_2020 AS (
    -- All 2020 orders placed AFTER January by any shopper
    SELECT
        "user_id",
        TO_CHAR(TO_TIMESTAMP_NTZ("created_at" / 1000000), 'YYYY-MM') AS "order_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE TO_CHAR(TO_TIMESTAMP_NTZ("created_at" / 1000000), 'YYYY') = '2020'
      AND TO_TIMESTAMP_NTZ("created_at" / 1000000) > '2020-01-31 23:59:59'
)
-- Final proportion of cohort users who returned each month
SELECT
    o."order_month",
    COUNT(DISTINCT o."user_id")                           AS "returning_users",
    cs."total_users"                                      AS "cohort_users",
    ROUND(COUNT(DISTINCT o."user_id") / cs."total_users", 4) AS "proportion_returned"
FROM orders_2020 o
JOIN jan2020_cohort c
     ON o."user_id" = c."user_id"
CROSS JOIN cohort_size cs
GROUP BY o."order_month", cs."total_users"
ORDER BY o."order_month";
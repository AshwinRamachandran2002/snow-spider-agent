WITH first_orders AS (   -- first purchase timestamp for every user
    SELECT 
        "user_id",
        MIN("created_at") AS "first_order_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
), 
cohort_jan2020 AS (      -- users whose very first order was placed in Jan-2020
    SELECT "user_id"
    FROM   first_orders
    WHERE  "first_order_ts" >= 1577836800000000   -- 2020-01-01 00:00:00 (µs)
       AND "first_order_ts" <  1580515200000000   -- 2020-02-01 00:00:00 (µs)
), 
monthly_returns AS (     -- how many of those users ordered again each later month in 2020
    SELECT  
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."created_at" / 1000000)) AS "order_month",
        COUNT(DISTINCT o."user_id")                                     AS "returning_users"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN   cohort_jan2020            c ON o."user_id" = c."user_id"
    WHERE  o."created_at" >= 1580515200000000      -- 2020-02-01
       AND o."created_at" <  1609459200000000      -- 2021-01-01
    GROUP BY 1
)
SELECT  
    m."order_month",
    m."returning_users",
    (SELECT COUNT(*) FROM cohort_jan2020)                                AS "cohort_size",
    ROUND(
        m."returning_users"::FLOAT 
        / NULLIF((SELECT COUNT(*) FROM cohort_jan2020),0)
    ,4)                                                                  AS "monthly_return_rate"
FROM   monthly_returns m
ORDER BY m."order_month";
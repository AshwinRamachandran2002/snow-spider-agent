WITH first_order_per_user AS (
    SELECT 
        "user_id",
        MIN(TO_TIMESTAMP("created_at"/1000000)::DATE) AS "first_order_dt"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
), 

jan20_cohort AS (
    SELECT "user_id"
    FROM first_order_per_user
    WHERE "first_order_dt" BETWEEN '2020-01-01' AND '2020-01-31'
), 

cohort_size AS (
    SELECT COUNT(DISTINCT "user_id") AS "cohort_size"
    FROM jan20_cohort
), 

subsequent_orders AS (
    SELECT 
        j."user_id",
        TO_CHAR(TO_TIMESTAMP(o."created_at"/1000000)::DATE, 'YYYY-MM') AS "yyyymm"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN jan20_cohort j
      ON o."user_id" = j."user_id"
    WHERE TO_TIMESTAMP(o."created_at"/1000000)::DATE BETWEEN '2020-02-01' AND '2020-12-31'
)

SELECT 
    s."yyyymm",
    COUNT(DISTINCT s."user_id") AS "returning_users",
    ROUND(COUNT(DISTINCT s."user_id") / c."cohort_size", 4) AS "proportion"
FROM subsequent_orders s
CROSS JOIN cohort_size c
GROUP BY s."yyyymm", c."cohort_size"
ORDER BY s."yyyymm";
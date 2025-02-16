-- Task: List the users who made their first purchase in January 2020.

WITH first_orders AS (
  SELECT "user_id", MIN("created_at") AS first_order_at
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
  GROUP BY "user_id"
)
SELECT fo."user_id", fo.first_order_at
FROM first_orders fo
WHERE TO_TIMESTAMP_NTZ(fo.first_order_at / 1000000) >= '2020-01-01' 
  AND TO_TIMESTAMP_NTZ(fo.first_order_at / 1000000) < '2020-02-01';
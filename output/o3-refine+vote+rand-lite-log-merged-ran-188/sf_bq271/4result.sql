SELECT
  /* month that the order was created (YYYY-MM) */
  TO_CHAR(
    DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."created_at" / 1000000)),
    'YYYY-MM'
  )                                                   AS "order_month",
  
  /* user’s country */
  u."country",
  
  /* product attributes */
  ii."product_department",
  ii."product_category",
  
  /* number of distinct orders in the month / slice */
  COUNT(DISTINCT o."order_id")                        AS "num_orders",
  
  /* number of distinct purchasers in the month / slice */
  COUNT(DISTINCT u."id")                              AS "unique_purchasers",
  
  /* profit = Σ(retail – cost), rounded to 4 decimals */
  ROUND(SUM(ii."product_retail_price" - ii."cost"), 4) AS "profit"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"          o
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"           u
     ON o."user_id" = u."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     oi
     ON oi."order_id" = o."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii
     ON ii."id" = oi."inventory_item_id"
WHERE 
      /* orders placed during calendar-year 2021 */
      o."created_at" BETWEEN 1609459200000000 AND 1640995199000000
    
  AND /* users registered during 2021 */
      u."created_at" BETWEEN 1609459200000000 AND 1640995199000000
    
  AND /* inventory items created during 2021 */
      ii."created_at" BETWEEN 1609459200000000 AND 1640995199000000
GROUP BY
  TO_CHAR(
    DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."created_at" / 1000000)),
    'YYYY-MM'
  ),
  u."country",
  ii."product_department",
  ii."product_category"
ORDER BY
  "order_month" ASC,
  u."country",
  ii."product_department",
  ii."product_category";
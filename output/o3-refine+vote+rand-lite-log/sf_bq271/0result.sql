SELECT
    TO_CHAR(
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1000000)),
        'YYYY-MM'
    )                                       AS "order_month",
    u."country"                             AS "country",
    ii."product_department"                 AS "product_department",
    ii."product_category"                   AS "product_category",
    COUNT(DISTINCT o."order_id")            AS "num_orders",
    COUNT(DISTINCT o."user_id")             AS "num_unique_purchasers",
    SUM(ii."product_retail_price" - ii."cost") AS "profit"
FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"          o
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     oi
      ON oi."order_id" = o."order_id"
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"           u
      ON u."id" = o."user_id"
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii
      ON ii."id" = oi."inventory_item_id"
WHERE TO_DATE(TO_TIMESTAMP_NTZ(o."created_at" / 1000000)) BETWEEN '2021-01-01' AND '2021-12-31'
  AND TO_DATE(TO_TIMESTAMP_NTZ(u."created_at" / 1000000)) BETWEEN '2021-01-01' AND '2021-12-31'
  AND TO_DATE(TO_TIMESTAMP_NTZ(ii."created_at" / 1000000)) BETWEEN '2021-01-01' AND '2021-12-31'
GROUP BY
    "order_month",
    u."country",
    ii."product_department",
    ii."product_category"
ORDER BY
    "order_month",
    u."country",
    ii."product_department",
    ii."product_category";
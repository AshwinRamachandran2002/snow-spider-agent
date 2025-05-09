SELECT
    DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)) AS sale_month,
    p."name"                                                        AS product_name,
    ROUND(SUM(oi."sale_price" - ii."cost"), 4)                      AS profit
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii
  ON oi."inventory_item_id" = ii."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p
  ON oi."product_id" = p."id"
WHERE oi."status" NOT ILIKE 'Cancelled'
  AND oi."status" NOT ILIKE 'Returned'
  AND oi."returned_at" IS NULL
  AND DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))
      BETWEEN '2019-01-01' AND '2022-08-31'
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
           PARTITION BY DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))
           ORDER BY SUM(oi."sale_price" - ii."cost") DESC
       ) <= 3
ORDER BY
    sale_month,
    profit DESC,
    product_name;
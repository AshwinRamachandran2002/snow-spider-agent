SELECT
    DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6))            AS "month",
    pr."name"                                                          AS "product_name",
    ROUND( SUM(oi."sale_price") - SUM(inv."cost"), 4 )                 AS "profit"
FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"        oi
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"    inv
       ON inv."id" = oi."inventory_item_id"
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"           pr
       ON pr."id" = oi."product_id"
WHERE  oi."status" = 'Complete'           -- exclude Cancelled / Returned items
  AND  oi."returned_at" IS NULL           -- ensure not subsequently returned
  AND  TO_TIMESTAMP(oi."created_at" / 1e6) >= '2019-01-01'
  AND  TO_TIMESTAMP(oi."created_at" / 1e6) <  '2022-09-01'      -- through Aug-2022
GROUP BY
       1, 2
QUALIFY
       ROW_NUMBER() OVER (
           PARTITION BY "month"
           ORDER BY (SUM(oi."sale_price") - SUM(inv."cost")) DESC
       ) <= 3                                                    -- top-3 per month
ORDER BY
       "month",
       "profit" DESC NULLS LAST;
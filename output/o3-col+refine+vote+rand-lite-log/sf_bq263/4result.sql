SELECT
       TO_CHAR(
           TO_TIMESTAMP_NTZ(oi."created_at" / 1000000),   -- µs-epoch → timestamp
           'YYYY-MM'
       )                                                 AS "month",
       SUM(oi."sale_price")                              AS "total_sales",
       SUM(ii."cost")                                    AS "total_cost",
       COUNT(DISTINCT oi."order_id")                     AS "complete_orders",
       SUM(oi."sale_price" - ii."cost")                  AS "total_profit",
       CASE
           WHEN SUM(ii."cost") <> 0
           THEN SUM(oi."sale_price" - ii."cost") / SUM(ii."cost")
       END                                               AS "profit_to_cost_ratio"
FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
       ON oi."inventory_item_id" = ii."id"
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
       ON oi."product_id" = p."id"
WHERE  p."category" = 'Sleep & Lounge'              -- focus category
  AND  oi."status"  = 'Complete'                    -- only completed orders
  AND  oi."created_at" BETWEEN 1672531200000000     -- 2023-01-01 00:00:00 UTC
                         AND 1704067199000000       -- 2023-12-31 23:59:59 UTC
GROUP BY 1
ORDER BY 1;
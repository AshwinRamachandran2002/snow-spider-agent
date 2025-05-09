SELECT
    DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))                       AS "month",
    ROUND(SUM(oi."sale_price"), 4)                                                    AS "total_sales",
    ROUND(SUM(p."cost"), 4)                                                           AS "total_cost",
    COUNT(DISTINCT oi."order_id")                                                     AS "complete_orders",
    ROUND(SUM(oi."sale_price" - p."cost"), 4)                                         AS "total_profit",
    ROUND(
        CASE 
            WHEN SUM(p."cost") = 0 THEN NULL
            ELSE SUM(oi."sale_price" - p."cost") / SUM(p."cost") 
        END
    , 4)                                                                              AS "profit_to_cost_ratio"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
  ON oi."product_id" = p."id"
WHERE p."category" = 'Sleep & Lounge'
  AND oi."status"   = 'Complete'
  AND oi."created_at" BETWEEN 1672531200000000   -- 2023‑01‑01 00:00:00 UTC
                         AND 1704067199000000   -- 2023‑12‑31 23:59:59 UTC
GROUP BY "month"
ORDER BY "month" ASC;
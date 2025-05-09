SELECT
    TO_CHAR(TO_TIMESTAMP(o."created_at" / 1e6), 'YYYY-MM')     AS "month",
    ROUND(SUM(oi."sale_price"), 2)                             AS "total_sales",
    ROUND(SUM(ii."cost"), 2)                                   AS "total_cost",
    COUNT(DISTINCT oi."order_id")                              AS "num_complete_orders",
    ROUND(SUM(oi."sale_price" - ii."cost"), 2)                 AS "total_profit",
    ROUND(
          SUM(oi."sale_price" - ii."cost") / NULLIF(SUM(ii."cost"), 0)
        , 4)                                                   AS "profit_to_cost_ratio"
FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS     oi
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS          o
       ON oi."order_id" = o."order_id"
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS ii
       ON oi."inventory_item_id" = ii."id"
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS        p
       ON oi."product_id" = p."id"
WHERE  p."category"        ILIKE '%sleep%lounge%'     -- restrict to "Sleep & Lounge"
  AND  oi."status"         = 'Complete'               -- order-item must be complete
  AND  o."status"          = 'Complete'               -- order must be complete
  AND  o."created_at" BETWEEN 1672531200000000        -- 2023-01-01 00:00:00
                         AND     1704067199000000     -- 2023-12-31 23:59:59
GROUP BY 1
ORDER BY 1;
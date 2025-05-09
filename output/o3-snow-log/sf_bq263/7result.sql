/* 2023 month-by-month performance of the “Sleep & Lounge” category */
SELECT
    TO_CHAR("order_month",'YYYY-MM')                       AS "month",
    "total_sales",
    "total_cost",
    "complete_orders",
    "total_profit",
    CASE WHEN "total_cost" = 0 THEN NULL
         ELSE ROUND("total_profit" / "total_cost", 10)     -- ratio
    END                                                    AS "profit_to_cost_ratio"
FROM  (
        SELECT
            DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6))
                                                            AS "order_month",
            SUM(oi."sale_price")                           AS "total_sales",
            SUM(ii."cost")                                 AS "total_cost",
            COUNT(DISTINCT oi."order_id")                  AS "complete_orders",
            SUM(oi."sale_price" - ii."cost")               AS "total_profit"
        FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"      oi
        JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"           o
               ON oi."order_id" = o."order_id"
        JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"         p
               ON oi."product_id" = p."id"
        JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS"  ii
               ON oi."inventory_item_id" = ii."id"
        WHERE  o."created_at" BETWEEN 1672531200000000 AND 1704067199000000   -- 2023
          AND  o."status"  = 'Complete'
          AND  oi."status" = 'Complete'
          AND  p."category" ILIKE '%Sleep%Lounge%'
        GROUP BY 1
      )
ORDER BY "order_month";
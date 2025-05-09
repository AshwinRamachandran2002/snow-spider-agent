/*  Month-by-month “Sleep & Lounge” performance report for calendar-year 2023  */
SELECT
       mth."month",
       mth."total_sales",
       mth."total_cost",
       mth."num_complete_orders",
       mth."total_profit",
       CASE
            WHEN mth."total_cost" <> 0
            THEN mth."total_profit" / mth."total_cost"
       END                                         AS "profit_to_cost_ratio"
FROM  (
        SELECT
               DATE_TRUNC('month',
                          TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
                         )                         AS "month",
               SUM(oi."sale_price")               AS "total_sales",
               SUM(ii."cost")                     AS "total_cost",
               SUM(oi."sale_price" - ii."cost")   AS "total_profit",
               COUNT(DISTINCT o."order_id")       AS "num_complete_orders"
        FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        o
        JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
               ON o."order_id" = oi."order_id"
        JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
               ON oi."inventory_item_id" = ii."id"
        JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
               ON oi."product_id" = p."id"
        WHERE  p."category" ILIKE '%Sleep%Lounge%'      -- focus on “Sleep & Lounge”
          AND  oi."status"   = 'Complete'               -- item level must be complete
          AND  o."status"    = 'Complete'               -- order level must be complete
          AND  o."created_at" BETWEEN 1672531200000000  -- 2023-01-01 00:00:00 UTC
                                 AND 1704067199000000   -- 2023-12-31 23:59:59 UTC
        GROUP BY 1
      ) mth
ORDER BY mth."month";
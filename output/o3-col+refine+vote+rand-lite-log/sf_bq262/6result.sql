/*---------------------------------------------------------------
Monthly sales & MoM growth by product category
   – Period analysed : 2019-06 to 2019-12
   – Growth baseline : 2019-06
   – Output          : 2019-07 … 2019-12 (June omitted)
----------------------------------------------------------------*/
WITH monthly AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP("oi"."created_at" / 1000000), 'YYYY-MM')       AS "month",
        "p"."category"                                                      AS "category",
        COUNT(DISTINCT "oi"."order_id")                                     AS "total_orders",
        SUM("oi"."sale_price")                                              AS "total_revenue",
        SUM("oi"."sale_price" - "p"."cost")                                 AS "total_profit"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "p"
           ON "oi"."product_id" = "p"."id"
    WHERE  TO_TIMESTAMP("oi"."created_at" / 1000000)
              BETWEEN '2019-06-01' AND '2019-12-31 23:59:59'
    GROUP  BY 1, 2
)

SELECT
    "cur"."month",
    "cur"."category",
    "cur"."total_orders",
    ROUND("cur"."total_revenue", 4)                                           AS "total_revenue",
    ROUND("cur"."total_profit", 4)                                            AS "total_profit",
    ROUND(100.0 * ("cur"."total_orders"  - COALESCE("jun"."total_orders",0))
               / NULLIF("jun"."total_orders",0), 4)                           AS "orders_growth_pct",
    ROUND(100.0 * ("cur"."total_revenue" - COALESCE("jun"."total_revenue",0))
               / NULLIF("jun"."total_revenue",0), 4)                          AS "revenue_growth_pct",
    ROUND(100.0 * ("cur"."total_profit"  - COALESCE("jun"."total_profit",0))
               / NULLIF("jun"."total_profit",0), 4)                           AS "profit_growth_pct"
FROM   monthly AS "cur"
LEFT JOIN monthly AS "jun"
       ON  "jun"."category" = "cur"."category"
      AND "jun"."month"     = '2019-06'
WHERE  "cur"."month" BETWEEN '2019-07' AND '2019-12'
ORDER  BY "cur"."month", "cur"."category";
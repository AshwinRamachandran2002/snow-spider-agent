/*  Monthly sales & MoM-growth by product category, Jul-Dec 2019                */
/*  (June 2019 is only the baseline that growth is compared against)            */

WITH sales AS (   -- 1. monthly aggregates for Jun-Dec 2019
    SELECT
        TO_CHAR(DATE_TRUNC('month'
                 , TO_TIMESTAMP("oi"."created_at" / 1000000)), 'YYYY-MM')        AS "month",
        "p"."category"                                                          AS "product_category",
        COUNT(DISTINCT "oi"."order_id")                                         AS "total_orders",
        SUM("oi"."sale_price")                                                  AS "total_revenue",
        SUM("oi"."sale_price" - "p"."cost")                                     AS "total_profit"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE TO_TIMESTAMP("oi"."created_at" / 1000000)
          BETWEEN '2019-06-01' AND '2019-12-31 23:59:59'
    GROUP BY "month", "product_category"
),
baseline AS (     -- 2. values for June 2019 (comparison base)
    SELECT
        "product_category",
        "total_orders"   AS "base_orders",
        "total_revenue"  AS "base_revenue",
        "total_profit"   AS "base_profit"
    FROM sales
    WHERE "month" = '2019-06'
)

-- 3. add growth figures and remove June from final output
SELECT
    "s"."month",
    "s"."product_category",
    "s"."total_orders",
    "s"."total_revenue",
    "s"."total_profit",
    ROUND( ( "s"."total_orders"  - "b"."base_orders")  / NULLIF("b"."base_orders", 0), 4) AS "orders_growth",
    ROUND( ( "s"."total_revenue" - "b"."base_revenue") / NULLIF("b"."base_revenue", 0), 4) AS "revenue_growth",
    ROUND( ( "s"."total_profit"  - "b"."base_profit")  / NULLIF("b"."base_profit", 0), 4) AS "profit_growth"
FROM  sales AS "s"
LEFT JOIN baseline AS "b"
       ON "s"."product_category" = "b"."product_category"
WHERE "s"."month" <> '2019-06'                      -- omit June in the report
ORDER BY "s"."month", "s"."product_category";
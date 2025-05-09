/*  Monthly category-level sales & profit with MoM growth
    (growth calculated versus June-2019 baseline, June itself omitted)  */

WITH item_details AS (   -- all order items between 2019-06-01 and 2019-12-31
    SELECT
        oi."order_id",
        p."category"          AS "product_category",
        oi."created_at",
        oi."sale_price",
        p."cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"    oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"       p
          ON oi."product_id" = p."id"
    WHERE TO_DATE(TO_TIMESTAMP(oi."created_at" / 1000000)) 
          BETWEEN '2019-06-01' AND '2019-12-31'
), 

monthly_category AS (    -- monthly roll-up
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1000000))::DATE 
            AS "month_start",
        "product_category",
        COUNT(DISTINCT "order_id")                        AS "total_orders",
        SUM("sale_price")                                 AS "total_revenue",
        SUM("sale_price" - "cost")                        AS "total_profit"
    FROM item_details
    GROUP BY "month_start", "product_category"
),

june_baseline AS (       -- June-2019 values (growth baseline)
    SELECT 
        "product_category",
        "total_orders"  AS "june_orders",
        "total_revenue" AS "june_revenue",
        "total_profit"  AS "june_profit"
    FROM monthly_category
    WHERE "month_start" = '2019-06-01'
),

growth_calc AS (         -- attach baseline & calculate growth
    SELECT
        mc."month_start",
        mc."product_category",
        mc."total_orders",
        mc."total_revenue",
        mc."total_profit",

        (mc."total_orders"  - jb."june_orders")  / NULLIF(jb."june_orders",  0) AS "orders_growth",
        (mc."total_revenue" - jb."june_revenue") / NULLIF(jb."june_revenue", 0) AS "revenue_growth",
        (mc."total_profit"  - jb."june_profit")  / NULLIF(jb."june_profit",  0) AS "profit_growth"
    FROM monthly_category mc
    LEFT JOIN june_baseline jb
           ON mc."product_category" = jb."product_category"
    WHERE mc."month_start" > '2019-06-01'          -- omit June from results
)

SELECT
    TO_CHAR("month_start", 'YYYY-MM')                            AS "month",
    "product_category",
    "total_orders",
    ROUND("total_revenue",  4)                                   AS "total_revenue",
    ROUND("total_profit",   4)                                   AS "total_profit",
    ROUND("orders_growth",  4)                                   AS "orders_growth_rate",
    ROUND("revenue_growth", 4)                                   AS "revenue_growth_rate",
    ROUND("profit_growth",  4)                                   AS "profit_growth_rate"
FROM growth_calc
ORDER BY "month_start" ASC, "product_category" ASC;
/*  Monthly sales & profit report (Jul-Dec 2019) with growth vs. Jun-2019  */
WITH june_baseline AS (          -- metrics per category for June 2019
    SELECT
        p."category",
        COUNT(DISTINCT oi."order_id")                     AS "orders_base",
        SUM(oi."sale_price")                             AS "revenue_base",
        SUM(oi."sale_price" - inv."cost")                AS "profit_base"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  inv
         ON oi."inventory_item_id" = inv."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
         ON oi."product_id" = p."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at"/1e6))
          = DATE '2019-06-01'
    GROUP BY p."category"
),
monthly_totals AS (             -- metrics per category for Jun-Dec 2019
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at"/1e6))  AS "month",
        p."category",
        COUNT(DISTINCT oi."order_id")                              AS "total_orders",
        SUM(oi."sale_price")                                       AS "total_revenue",
        SUM(oi."sale_price" - inv."cost")                          AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  inv
         ON oi."inventory_item_id" = inv."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
         ON oi."product_id" = p."id"
    WHERE TO_TIMESTAMP_NTZ(oi."created_at"/1e6)
          BETWEEN DATE '2019-06-01' AND DATE '2019-12-31'
    GROUP BY 1, p."category"
)
SELECT
    TO_CHAR(mt."month", 'YYYY-MM')                                         AS "month",
    mt."category",
    mt."total_orders",
    mt."total_revenue",
    mt."total_profit",
    (mt."total_orders"  - jb."orders_base")  / NULLIF(jb."orders_base",0)::FLOAT   AS "orders_growth_rate",
    (mt."total_revenue" - jb."revenue_base") / NULLIF(jb."revenue_base",0)::FLOAT  AS "revenue_growth_rate",
    (mt."total_profit"  - jb."profit_base")  / NULLIF(jb."profit_base",0)::FLOAT   AS "profit_growth_rate"
FROM monthly_totals  mt
LEFT JOIN june_baseline  jb
       ON mt."category" = jb."category"
WHERE mt."month" > DATE '2019-06-01'      -- omit June from final output
ORDER BY "month", mt."category";
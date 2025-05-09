/*  Monthly category-level performance
    – June 2019 data are used as the MoM comparison base
    – Output shows July-2019 → December-2019 (June is excluded from the final list)
*/
WITH monthly AS (
    SELECT  
        DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))   AS month_start ,
        p."category"                                                      AS category     ,
        COUNT(DISTINCT oi."order_id")                                     AS total_orders ,
        SUM(oi."sale_price")                                              AS total_revenue,
        SUM(oi."sale_price" - ii."cost")                                  AS total_profit
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
           ON oi."inventory_item_id" = ii."id"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
           ON oi."product_id" = p."id"
    WHERE  oi."created_at" >= 1559347200000000        -- 01-Jun-2019 00:00:00
      AND  oi."created_at" <  1577836800000000        -- 01-Jan-2020 00:00:00
    GROUP BY month_start, p."category"
),
monthly_with_growth AS (
    SELECT
        month_start,
        category,
        total_orders,
        total_revenue,
        total_profit,
        ( total_orders - LAG(total_orders)  OVER (PARTITION BY category ORDER BY month_start) )
          / NULLIF(LAG(total_orders)  OVER (PARTITION BY category ORDER BY month_start), 0)  AS orders_mom_growth,
        ( total_revenue - LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_start) )
          / NULLIF(LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_start), 0) AS revenue_mom_growth,
        ( total_profit - LAG(total_profit)  OVER (PARTITION BY category ORDER BY month_start) )
          / NULLIF(LAG(total_profit)  OVER (PARTITION BY category ORDER BY month_start), 0) AS profit_mom_growth
    FROM monthly
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM')  AS "month",
    category,
    total_orders,
    total_revenue,
    total_profit,
    orders_mom_growth,
    revenue_mom_growth,
    profit_mom_growth
FROM   monthly_with_growth
WHERE  month_start >= DATE '2019-07-01'     -- omit June from final output
ORDER BY month_start, category;
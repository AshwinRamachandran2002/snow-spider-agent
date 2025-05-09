WITH monthly_metrics AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY-MM') AS "month",
        p."category"                                                    AS "product_category",
        COUNT(DISTINCT oi."order_id")                                   AS "total_orders",
        SUM(oi."sale_price")                                            AS "total_revenue",
        SUM(oi."sale_price" - ii."cost")                                AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
         ON ii."id" = oi."inventory_item_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
         ON p."id" = oi."product_id"
    WHERE TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY-MM')
          BETWEEN '2019-06' AND '2019-12'
    GROUP BY 1, 2
),
monthly_growth AS (
    SELECT
        mm.*,
        ROUND(
            (mm."total_revenue"
             - LAG(mm."total_revenue") OVER (PARTITION BY mm."product_category" ORDER BY mm."month"))
            / NULLIF(LAG(mm."total_revenue") OVER (PARTITION BY mm."product_category" ORDER BY mm."month"), 0)
            * 100, 2)                                                   AS "revenue_mom_growth_pct",
        ROUND(
            (mm."total_profit"
             - LAG(mm."total_profit") OVER (PARTITION BY mm."product_category" ORDER BY mm."month"))
            / NULLIF(LAG(mm."total_profit") OVER (PARTITION BY mm."product_category" ORDER BY mm."month"), 0)
            * 100, 2)                                                   AS "profit_mom_growth_pct"
    FROM monthly_metrics mm
)
SELECT
    "month",
    "product_category",
    "total_orders",
    "total_revenue",
    "total_profit",
    "revenue_mom_growth_pct",
    "profit_mom_growth_pct"
FROM monthly_growth
WHERE "month" <> '2019-06'          -- exclude June 2019 from final output
ORDER BY "month", "product_category";
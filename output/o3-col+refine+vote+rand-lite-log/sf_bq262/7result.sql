/* Monthly category performance (Jun-Dec 2019) with MoM growth –
   June is used as the baseline but excluded from the final output */
WITH monthly AS (
    SELECT
        TO_CHAR(
            DATE_TRUNC(
                'month',
                TO_TIMESTAMP(oi."created_at" / 1000000)
            ),
            'YYYY-MM'
        )                                              AS "month",
        p."category"                                   AS "product_category",
        COUNT(DISTINCT oi."order_id")                  AS "total_orders",
        ROUND(SUM(oi."sale_price"), 4)                 AS "total_revenue",
        ROUND(SUM(oi."sale_price" - p."cost"), 4)      AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
         ON p."id" = oi."product_id"
    WHERE TO_TIMESTAMP(oi."created_at" / 1000000)
          BETWEEN TO_TIMESTAMP('2019-06-01')
              AND TO_TIMESTAMP('2019-12-31 23:59:59')
    GROUP BY 1, 2
),
with_growth AS (
    SELECT
        m.*,
        LAG(m."total_orders")  OVER (PARTITION BY m."product_category"
                                     ORDER BY TO_DATE(m."month"||'-01')) AS "prev_orders",
        LAG(m."total_revenue") OVER (PARTITION BY m."product_category"
                                     ORDER BY TO_DATE(m."month"||'-01')) AS "prev_revenue",
        LAG(m."total_profit")  OVER (PARTITION BY m."product_category"
                                     ORDER BY TO_DATE(m."month"||'-01')) AS "prev_profit"
    FROM monthly m
)
SELECT
    "month",
    "product_category",
    "total_orders",
    "total_revenue",
    "total_profit",
    ROUND(( "total_orders"  / NULLIF("prev_orders",  0) - 1 ) * 100, 2) AS "orders_mom_growth_pct",
    ROUND(( "total_revenue" / NULLIF("prev_revenue", 0) - 1 ) * 100, 2) AS "revenue_mom_growth_pct",
    ROUND(( "total_profit"  / NULLIF("prev_profit",  0) - 1 ) * 100, 2) AS "profit_mom_growth_pct"
FROM with_growth
WHERE "month" >= '2019-07'            -- omit June from final output
ORDER BY "month", "product_category";
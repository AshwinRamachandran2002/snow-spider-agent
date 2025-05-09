/* ----------------------------------------------------------
   Monthly sales & MoM growth report (Jun-2019 — Dec-2019)
-----------------------------------------------------------*/
WITH monthly AS (   -- metrics for every month / category
    SELECT
        TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1000000), 'YYYY-MM')  AS "year_month",
        p."category"                                                AS "category",
        COUNT(DISTINCT oi."order_id")                               AS "total_orders",
        SUM(oi."sale_price")                                        AS "total_revenue",
        SUM(oi."sale_price" - p."cost")                             AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
          ON oi."product_id" = p."id"
    WHERE TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1000000), 'YYYY-MM')
          BETWEEN '2019-06' AND '2019-12'            -- Jun baseline through Dec
    GROUP BY 1, 2
),
june AS (            -- June-2019 baseline (one row per category)
    SELECT
        m."category",
        m."total_orders"  AS "jun_orders",
        m."total_revenue" AS "jun_revenue",
        m."total_profit"  AS "jun_profit"
    FROM monthly m
    WHERE m."year_month" = '2019-06'
)

SELECT
    m."year_month",                      -- Month (YYYY-MM)
    m."category",                        -- Product category
    m."total_orders",                    -- Total # orders
    m."total_revenue",                   -- Total revenue
    m."total_profit",                    -- Total profit
    /* ---------- MoM growth vs. June baseline ---------- */
    ROUND( (m."total_orders"  - j."jun_orders")  / NULLIF(j."jun_orders",  0) * 100 , 2)  AS "orders_growth_pct",
    ROUND( (m."total_revenue" - j."jun_revenue") / NULLIF(j."jun_revenue", 0) * 100 , 2)  AS "revenue_growth_pct",
    ROUND( (m."total_profit"  - j."jun_profit")  / NULLIF(j."jun_profit",  0) * 100 , 2)  AS "profit_growth_pct"
FROM monthly m
LEFT JOIN june j         -- left join so categories appearing after June are retained
       ON m."category" = j."category"
WHERE m."year_month" <> '2019-06'          -- exclude June from final output
ORDER BY
    m."year_month" ASC,
    m."category"    ASC;
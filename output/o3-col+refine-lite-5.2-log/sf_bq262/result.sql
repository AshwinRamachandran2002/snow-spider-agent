/*-------------------------------------------------------------
  Monthly sales & profit report (Jun‑2019 – Dec‑2019)
  – Calculates totals per product category
  – Computes MoM growth beginning Jul‑2019 (June used as base)
  – All order‑item records included, regardless of status
--------------------------------------------------------------*/
WITH "monthly" AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY-MM') AS "month",
        p."category"                                                   AS "category",
        COUNT(*)                                                       AS "total_orders",
        SUM(oi."sale_price")                                           AS "total_revenue",
        SUM(oi."sale_price" - p."cost")                                AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id" = oi."product_id"
    WHERE TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
          BETWEEN '2019-06-01' AND '2019-12-31'
    GROUP BY 1, 2
)

SELECT
    m."month",
    m."category",
    m."total_orders",
    ROUND(
        (m."total_orders"
         - LAG(m."total_orders") OVER (PARTITION BY m."category" ORDER BY m."month"))
        / NULLIF(LAG(m."total_orders") OVER (PARTITION BY m."category" ORDER BY m."month"), 0),
        4
    ) AS "orders_growth",
    m."total_revenue",
    ROUND(
        (m."total_revenue"
         - LAG(m."total_revenue") OVER (PARTITION BY m."category" ORDER BY m."month"))
        / NULLIF(LAG(m."total_revenue") OVER (PARTITION BY m."category" ORDER BY m."month"), 0),
        4
    ) AS "revenue_growth",
    m."total_profit",
    ROUND(
        (m."total_profit"
         - LAG(m."total_profit") OVER (PARTITION BY m."category" ORDER BY m."month"))
        / NULLIF(LAG(m."total_profit") OVER (PARTITION BY m."category" ORDER BY m."month"), 0),
        4
    ) AS "profit_growth"
FROM "monthly" m
WHERE m."month" <> '2019-06'      -- exclude baseline month from final output
ORDER BY
    m."month",
    m."category";
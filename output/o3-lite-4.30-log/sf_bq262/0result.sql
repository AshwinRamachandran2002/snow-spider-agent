WITH monthly AS (
    /* Aggregate June‑to‑December‑2019 metrics by month & product category */
    SELECT
        TO_CHAR(TO_TIMESTAMP(O."created_at" / 1000000), 'YYYY-MM') AS "month",
        P."category"                                               AS "product_category",
        COUNT(DISTINCT O."order_id")                               AS "total_orders",
        ROUND(SUM(OI."sale_price"), 4)                             AS "total_revenue",
        ROUND(SUM(OI."sale_price" - P."cost"), 4)                  AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" OI
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     P ON OI."product_id" = P."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       O ON OI."order_id"  = O."order_id"
    WHERE O."created_at" BETWEEN 1559347200000000  /* 2019‑06‑01 */
                             AND 1577836799000000  /* 2019‑12‑31 */
    GROUP BY 1, 2
),
june AS (
    /* June‑2019 baseline for MoM growth calculations */
    SELECT
        "product_category",
        "total_orders"  AS "orders_june",
        "total_revenue" AS "revenue_june",
        "total_profit"  AS "profit_june"
    FROM monthly
    WHERE "month" = '2019-06'
)
SELECT
    m."month",
    m."product_category",
    m."total_orders",
    m."total_revenue",
    m."total_profit",
    ROUND(100 * (m."total_orders"  - j."orders_june")  / NULLIF(j."orders_june",  0), 4) AS "orders_mom_growth",
    ROUND(100 * (m."total_revenue" - j."revenue_june") / NULLIF(j."revenue_june", 0), 4) AS "revenue_mom_growth",
    ROUND(100 * (m."total_profit"  - j."profit_june")  / NULLIF(j."profit_june",  0), 4) AS "profit_mom_growth"
FROM   monthly m
JOIN   june    j  ON m."product_category" = j."product_category"
WHERE  m."month" <> '2019-06'          /* exclude June from final output */
ORDER  BY m."month", m."product_category";
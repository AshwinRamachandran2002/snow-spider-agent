WITH completed AS (  -- order‑items that were completed and delivered before 2022
    SELECT
        oi."order_id"      AS ORDER_ID,
        oi."product_id"    AS PRODUCT_ID,
        p."category"       AS CATEGORY,
        p."cost"           AS PRODUCT_COST,
        oi."sale_price"    AS SALE_PRICE,
        TO_DATE(TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000)) AS DELIVERED_DATE
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000) < '2022-01-01'
),
monthly AS (  -- monthly aggregation per product category
    SELECT
        CATEGORY,
        DATE_TRUNC('month', DELIVERED_DATE)               AS MONTH_START,
        SUM(SALE_PRICE)                                   AS REVENUE,
        COUNT(DISTINCT ORDER_ID)                          AS COMPLETED_ORDERS,
        SUM(PRODUCT_COST)                                 AS TOTAL_COST,
        SUM(SALE_PRICE) - SUM(PRODUCT_COST)               AS TOTAL_PROFIT,
        CASE
            WHEN SUM(PRODUCT_COST) <> 0
            THEN (SUM(SALE_PRICE) - SUM(PRODUCT_COST)) / SUM(PRODUCT_COST)
        END                                               AS PROFIT_TO_COST_RATIO
    FROM completed
    GROUP BY CATEGORY, DATE_TRUNC('month', DELIVERED_DATE)
)
SELECT
    CATEGORY,
    MONTH_START,
    REVENUE,
    COMPLETED_ORDERS,
    ROUND(
        (REVENUE - LAG(REVENUE) OVER (PARTITION BY CATEGORY ORDER BY MONTH_START))
        / NULLIF(LAG(REVENUE) OVER (PARTITION BY CATEGORY ORDER BY MONTH_START), 0) * 100,
        4
    )                                                    AS REVENUE_MOM_GROWTH_PCT,
    ROUND(
        (COMPLETED_ORDERS - LAG(COMPLETED_ORDERS) OVER (PARTITION BY CATEGORY ORDER BY MONTH_START))
        / NULLIF(LAG(COMPLETED_ORDERS) OVER (PARTITION BY CATEGORY ORDER BY MONTH_START), 0) * 100,
        4
    )                                                    AS ORDERS_MOM_GROWTH_PCT,
    TOTAL_COST,
    TOTAL_PROFIT,
    ROUND(PROFIT_TO_COST_RATIO, 4)                       AS PROFIT_TO_COST_RATIO
FROM monthly
ORDER BY CATEGORY, MONTH_START;
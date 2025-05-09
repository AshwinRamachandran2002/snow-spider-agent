/*  Monthly performance per product category
    – only orders with status = 'Complete'
    – delivered before 2022-01-01 (micro-seconds epoch < 1640995200000000)
*/

WITH "monthly" AS (
    SELECT
        P."category" AS "category",
        TO_CHAR(
            DATE_TRUNC(
                'month',
                TO_TIMESTAMP_NTZ( O."delivered_at" / 1000000 )
            ),
            'YYYY-MM'
        )                               AS "yr_mo",
        SUM( O."sale_price" )           AS "revenue",
        COUNT(*)                        AS "orders",
        SUM( P."cost" )                 AS "cost"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  O
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"      P
      ON O."product_id" = P."id"
    WHERE O."status"       = 'Complete'
      AND O."delivered_at" IS NOT NULL
      AND O."delivered_at" < 1640995200000000      -- 2022-01-01 in µs
    GROUP BY
        P."category",
        TO_CHAR(
            DATE_TRUNC(
                'month',
                TO_TIMESTAMP_NTZ( O."delivered_at" / 1000000 )
            ),
            'YYYY-MM'
        )
)

SELECT
    "category",
    "yr_mo",
    "revenue",
    "orders",
    ROUND(
        100 * (
            "revenue" - LAG("revenue") OVER (PARTITION BY "category" ORDER BY "yr_mo")
        ) / NULLIF(
            LAG("revenue") OVER (PARTITION BY "category" ORDER BY "yr_mo"), 0
        ), 4
    ) AS "revenue_mom_pct",
    ROUND(
        100 * (
            "orders" - LAG("orders") OVER (PARTITION BY "category" ORDER BY "yr_mo")
        ) / NULLIF(
            LAG("orders") OVER (PARTITION BY "category" ORDER BY "yr_mo"), 0
        ), 4
    ) AS "orders_mom_pct",
    "cost",
    "revenue" - "cost"                  AS "profit",
    ROUND( ("revenue" - "cost") / NULLIF("cost", 0), 4 ) AS "profit_to_cost_ratio"
FROM "monthly"
ORDER BY
    "category",
    "yr_mo";
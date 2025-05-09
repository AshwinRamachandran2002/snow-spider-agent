WITH order_items_with_cost AS (
    /* enrich every order-item with its product-cost and month */
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP("oi"."created_at" / 1000000.0))          AS "month",
        "oi"."product_id",
        COALESCE("p"."name", 'UNKNOWN')                                 AS "product_name",
        COALESCE("p"."cost", 0)                                         AS "unit_cost",
        COALESCE("oi"."sale_price", 0)                                  AS "sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  AS "oi"
    LEFT JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS AS "p"
           ON "oi"."product_id" = "p"."id"
    /* only months strictly before January-2024 */
    WHERE TO_TIMESTAMP("oi"."created_at" / 1000000.0) < DATE '2024-01-01'
), 

monthly_product_profit AS (
    /* aggregate profit & cost per product per month */
    SELECT
        "month",
        "product_id",
        "product_name",
        SUM("unit_cost")                                   AS "total_cost",
        SUM("sale_price" - "unit_cost")                    AS "total_profit"
    FROM order_items_with_cost
    GROUP BY "month", "product_id", "product_name"
), 

ranked AS (
    /* pick the most profitable product for each month */
    SELECT
        "month",
        "product_id",
        "product_name",
        "total_cost",
        "total_profit",
        ROW_NUMBER() OVER (PARTITION BY "month"
                           ORDER BY "total_profit" DESC NULLS LAST) AS "rn"
    FROM monthly_product_profit
)

SELECT
    TO_CHAR("month", 'YYYY-MM')                           AS "month",
    "product_id",
    "product_name",
    ROUND("total_cost",   4)                              AS "total_cost",
    ROUND("total_profit", 4)                              AS "total_profit"
FROM ranked
WHERE "rn" = 1                       -- top product of each month
ORDER BY "month";
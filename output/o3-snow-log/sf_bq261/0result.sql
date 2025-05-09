WITH order_items_enriched AS (
    /* 1.  Join each order item with its product to bring in the product-level cost
          and convert the microsecond epoch into a Snowflake timestamp, then a month */
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("oi"."created_at" / 1000000)      -- microseconds → seconds → timestamp
        )                                     AS "order_month",
        "oi"."product_id"                     AS "product_id",
        "p"."name"                            AS "product_name",
        "p"."cost"                            AS "unit_cost",
        "oi"."sale_price"                     AS "sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "p"
      ON "oi"."product_id" = "p"."id"
    WHERE TO_TIMESTAMP("oi"."created_at" / 1000000) < '2024-01-01'   -- exclude Jan-2024 and later
), monthly_product_profit AS (
    /* 2.  Aggregate profit and cost per product per month */
    SELECT
        "order_month",
        "product_id",
        "product_name",
        SUM("unit_cost")                                   AS "total_cost",
        SUM("sale_price" - "unit_cost")                    AS "total_profit"
    FROM order_items_enriched
    GROUP BY
        "order_month",
        "product_id",
        "product_name"
), ranked_monthly_products AS (
    /* 3.  Rank products within each month by total profit (highest first) */
    SELECT
        "order_month",
        "product_id",
        "product_name",
        "total_cost",
        "total_profit",
        ROW_NUMBER() OVER (
            PARTITION BY "order_month"
            ORDER BY "total_profit" DESC
        ) AS "rn"
    FROM monthly_product_profit
)
-- 4.  Return the top-profit product for each month, chronologically
SELECT
    "order_month",
    "product_id",
    "product_name",
    ROUND("total_cost",   4) AS "total_cost",
    ROUND("total_profit", 4) AS "total_profit"
FROM ranked_monthly_products
WHERE "rn" = 1
ORDER BY "order_month";
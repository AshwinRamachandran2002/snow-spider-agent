WITH order_item_monthly AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at" / 1000000))  AS "order_month",
        "oi"."product_id",
        SUM("p"."cost")                                                 AS "total_cost",
        SUM("oi"."sale_price" - "p"."cost")                             AS "total_profit"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   AS "oi"
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE
        TO_TIMESTAMP("oi"."created_at" / 1000000) < '2024-01-01'
    GROUP BY
        "order_month",
        "oi"."product_id"
),
ranked_products AS (
    SELECT
        "order_month",
        "product_id",
        "total_cost",
        "total_profit",
        RANK() OVER (
            PARTITION BY "order_month"
            ORDER BY "total_profit" DESC
        ) AS "rnk"
    FROM order_item_monthly
)
SELECT
    "order_month",
    "product_id",
    "total_cost",
    "total_profit"
FROM ranked_products
WHERE "rnk" = 1
ORDER BY
    "order_month" ASC;
/*  Top-3 most profitable products per month (Jan-2019 – Aug-2022)  */
WITH base AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("oi"."created_at" / 1e6)
        )                                               AS "order_month",
        "p"."name"                                      AS "product_name",
        SUM("oi"."sale_price")                          AS "revenue",
        SUM("ii"."cost")                                AS "cost",
        SUM("oi"."sale_price") - SUM("ii"."cost")       AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" AS "ii"
      ON "oi"."inventory_item_id" = "ii"."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        AS "p"
      ON "oi"."product_id" = "p"."id"
    WHERE "oi"."status"      NOT ILIKE '%cancel%'
      AND "oi"."returned_at" IS NULL
      AND TO_TIMESTAMP("oi"."created_at" / 1e6)
            BETWEEN '2019-01-01' AND '2022-08-31 23:59:59'
    GROUP BY
        1, 2                       -- order_month, product_name
),
ranked AS (
    SELECT
        "order_month",
        "product_name",
        "profit",
        RANK() OVER (
            PARTITION BY "order_month"
            ORDER BY "profit" DESC NULLS LAST
        ) AS "profit_rank"
    FROM base
)
SELECT
    "order_month",
    "product_name",
    ROUND("profit", 4)   AS "profit",
    "profit_rank"
FROM ranked
WHERE "profit_rank" <= 3
ORDER BY
    "order_month",
    "profit_rank";
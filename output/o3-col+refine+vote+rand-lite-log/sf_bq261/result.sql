WITH monthly_profit AS (
    SELECT 
        TO_CHAR(TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000), 'YYYY-MM') AS "order_month",
        "oi"."product_id",
        SUM("p"."cost")                                                   AS "total_cost",
        SUM("oi"."sale_price" - "p"."cost")                               AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "p"
      ON "oi"."product_id" = "p"."id"
    WHERE TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000) < '2024-01-01'
    GROUP BY 1, 2
),
ranked AS (
    SELECT
        "mp".*,
        ROW_NUMBER() OVER (
            PARTITION BY "mp"."order_month"
            ORDER BY "mp"."total_profit" DESC
        ) AS "rn"
    FROM monthly_profit "mp"
)
SELECT
    "r"."order_month"  AS "month",
    "r"."product_id",
    "pr"."name"        AS "product_name",
    "r"."total_cost",
    "r"."total_profit"
FROM ranked "r"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" AS "pr"
  ON "r"."product_id" = "pr"."id"
WHERE "r"."rn" = 1
ORDER BY "r"."order_month";
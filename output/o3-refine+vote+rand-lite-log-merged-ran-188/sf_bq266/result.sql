WITH sales_2020 AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000))  AS "sale_month",
        "p"."name"                                                         AS "product_name",
        ("p"."retail_price" - "p"."cost")                                   AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE "oi"."created_at" IS NOT NULL
      AND DATE_PART('year', TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000)) = 2020
      AND "oi"."status" <> 'Cancelled'              -- consider only completed/shipped sales
),
lowest_profit_per_month AS (
    SELECT
        "sale_month",
        "product_name",
        "profit",
        RANK() OVER (PARTITION BY "sale_month"
                     ORDER BY "profit" ASC)          AS "profit_rank"
    FROM sales_2020
)
SELECT
    TO_CHAR("sale_month", 'YYYY-MM')  AS "month",
    "product_name"
FROM lowest_profit_per_month
WHERE "profit_rank" = 1                       -- lowest‑profit product(s) for the month
ORDER BY "sale_month" ASC, "product_name";
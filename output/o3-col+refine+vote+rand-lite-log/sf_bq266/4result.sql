WITH "sales_2020" AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("I"."sold_at" / 1000000))       AS "month_start",
        "P"."name"                                                           AS "product_name",
        ("P"."retail_price" - "P"."cost")                                    AS "profit"
    FROM  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS"  AS "I"
    JOIN  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"         AS "P"
          ON "I"."product_id" = "P"."id"
    WHERE "I"."sold_at" BETWEEN 1577836800000000 AND 1609459199000000     -- only sales in 2020
),
"ranked" AS (
    SELECT
        TO_CHAR("month_start", 'YYYY-MM')                                   AS "month_2020",
        "product_name",
        ROW_NUMBER() OVER (
            PARTITION BY "month_start"
            ORDER BY ("profit") ASC
        )                                                                   AS "rn"
    FROM "sales_2020"
)
SELECT
    "month_2020",
    "product_name"
FROM "ranked"
WHERE "rn" = 1
ORDER BY "month_2020";
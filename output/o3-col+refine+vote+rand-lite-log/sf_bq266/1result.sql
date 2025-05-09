-- Products that recorded the lowest profit (retail_price – cost) in each month of 2020
WITH sales_2020 AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_LTZ(ii."sold_at" / 1000000), 'YYYY-MM') AS "yyyymm",
        p."name"                                                     AS "product_name",
        (p."retail_price" - p."cost")                                AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" AS ii
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        AS p
      ON ii."product_id" = p."id"
    WHERE ii."sold_at" IS NOT NULL
      AND ii."sold_at" >= 1577836800000000        -- 2020-01-01 00:00:00 UTC
      AND ii."sold_at" <  1609459200000000        -- 2021-01-01 00:00:00 UTC
)

SELECT DISTINCT
       "yyyymm",
       "product_name"
FROM sales_2020
QUALIFY "profit" = MIN("profit") OVER (PARTITION BY "yyyymm")
ORDER BY "yyyymm";
WITH product_counts AS (
    SELECT
        d."segment",
        COUNT(DISTINCT CASE WHEN f."fiscal_year" = 2020 THEN f."product_code" END) AS "unique_products_2020",
        COUNT(DISTINCT CASE WHEN f."fiscal_year" = 2021 THEN f."product_code" END) AS "unique_products_2021"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY  f
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT         d
      ON f."product_code" = d."product_code"
    WHERE f."fiscal_year" IN (2020, 2021)
    GROUP BY d."segment"
)

SELECT
    "segment",
    "unique_products_2020",
    ROUND(
         ( "unique_products_2021" - "unique_products_2020") * 100.0
         / NULLIF("unique_products_2020", 0)
    , 2) AS "percentage_increase"
FROM product_counts
WHERE "unique_products_2020" > 0          -- avoid divide-by-zero and keep relevant segments
ORDER BY "percentage_increase" DESC NULLS LAST;
WITH seg AS (
    SELECT 
        p."segment",
        COUNT(DISTINCT CASE WHEN s."fiscal_year" = 2020 THEN s."product_code" END) AS "unique_products_2020",
        COUNT(DISTINCT CASE WHEN s."fiscal_year" = 2021 THEN s."product_code" END) AS "unique_products_2021"
    FROM "hardware_fact_sales_monthly" AS s
    JOIN "hardware_dim_product"        AS p
      ON p."product_code" = s."product_code"
    WHERE s."fiscal_year" IN (2020, 2021)
    GROUP BY p."segment"
)
SELECT
    "segment",
    "unique_products_2020"
FROM (
    SELECT 
        "segment",
        "unique_products_2020",
        /* percentage increase used only for ordering */
        (CAST(("unique_products_2021" - "unique_products_2020") AS REAL) * 100.0) /
        NULLIF("unique_products_2020", 0) AS pct_increase
    FROM seg
)
WHERE "unique_products_2020" > 0          -- ensure valid denominator
ORDER BY pct_increase DESC;
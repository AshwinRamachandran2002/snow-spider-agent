WITH product_sales AS (
    SELECT
        dp."segment",
        fs."fiscal_year",
        fs."product_code"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY AS fs
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT           AS dp
          ON fs."product_code" = dp."product_code"
    WHERE fs."fiscal_year" IN (2020, 2021)
), agg AS (
    SELECT
        "segment",
        COUNT(DISTINCT CASE WHEN "fiscal_year" = 2020 THEN "product_code" END) AS unique_products_2020,
        COUNT(DISTINCT CASE WHEN "fiscal_year" = 2021 THEN "product_code" END) AS unique_products_2021
    FROM product_sales
    GROUP BY "segment"
)
SELECT
    "segment",
    unique_products_2020
FROM (
    SELECT
        "segment",
        unique_products_2020,
        unique_products_2021,
        (unique_products_2021 - unique_products_2020) * 100.0
            / NULLIF(unique_products_2020, 0)                        AS pct_increase
    FROM agg
)
ORDER BY pct_increase DESC NULLS LAST;
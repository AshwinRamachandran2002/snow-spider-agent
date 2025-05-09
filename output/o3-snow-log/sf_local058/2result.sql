WITH product_counts AS (
    SELECT
        p."segment"                                                             AS segment,
        COUNT(DISTINCT CASE WHEN f."fiscal_year" = 2020 THEN f."product_code" END) AS unique_products_2020,
        COUNT(DISTINCT CASE WHEN f."fiscal_year" = 2021 THEN f."product_code" END) AS unique_products_2021
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_FACT_SALES_MONTHLY" f
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_DIM_PRODUCT"        p
      ON f."product_code" = p."product_code"
    WHERE f."fiscal_year" IN (2020, 2021)
    GROUP BY p."segment"
),
pct_calc AS (
    SELECT
        segment,
        unique_products_2020,
        unique_products_2021,
        CASE 
            WHEN unique_products_2020 = 0 THEN NULL
            ELSE (unique_products_2021 - unique_products_2020) * 100.0 / unique_products_2020
        END AS pct_increase
    FROM product_counts
)
SELECT
    segment,
    unique_products_2020
FROM pct_calc
ORDER BY pct_increase DESC NULLS LAST;
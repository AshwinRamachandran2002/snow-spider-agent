WITH sales_products AS (
    SELECT 
        fs."product_code",
        fs."fiscal_year",
        dp."segment"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY fs
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT     dp
          ON fs."product_code" = dp."product_code"
    WHERE fs."fiscal_year" IN (2020, 2021)
),
segment_counts AS (
    SELECT
        "segment",
        COUNT(DISTINCT CASE WHEN "fiscal_year" = 2020 THEN "product_code" END) AS unique_products_2020,
        COUNT(DISTINCT CASE WHEN "fiscal_year" = 2021 THEN "product_code" END) AS unique_products_2021
    FROM sales_products
    GROUP BY "segment"
),
percent_change AS (
    SELECT
        "segment",
        unique_products_2020,
        unique_products_2021,
        /* percentage increase; NULL when 2020 count is 0 to avoid divide-by-zero */
        CASE 
            WHEN unique_products_2020 = 0 THEN NULL
            ELSE ( (unique_products_2021 - unique_products_2020) / unique_products_2020 ) * 100
        END AS pct_increase
    FROM segment_counts
)
SELECT
    "segment",
    unique_products_2020   AS "unique_product_count_2020"
FROM percent_change
WHERE unique_products_2020 > 0           -- keep only segments that existed in 2020
ORDER BY pct_increase DESC NULLS LAST;
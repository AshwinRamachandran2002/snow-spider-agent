WITH year_counts AS (
    SELECT 
        dp."segment"                      AS segment,
        fm."fiscal_year"                  AS fiscal_year,
        COUNT(DISTINCT fm."product_code") AS unique_products
    FROM "hardware_fact_sales_monthly" fm
    JOIN "hardware_dim_product" dp
      ON dp."product_code" = fm."product_code"
    WHERE fm."fiscal_year" IN (2020, 2021)
    GROUP BY dp."segment", fm."fiscal_year"
),
pivot AS (
    SELECT
        segment,
        MAX(CASE WHEN fiscal_year = 2020 THEN unique_products END) AS cnt_2020,
        MAX(CASE WHEN fiscal_year = 2021 THEN unique_products END) AS cnt_2021
    FROM year_counts
    GROUP BY segment
)
SELECT
    segment  AS product_segment,
    cnt_2020 AS unique_products_2020
FROM pivot
ORDER BY 
    (COALESCE(cnt_2021,0) - COALESCE(cnt_2020,0)) * 1.0 / NULLIF(cnt_2020,0) DESC,
    segment;
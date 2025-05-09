WITH segment_counts AS (
    SELECT
        dp.segment,
        COUNT(DISTINCT CASE WHEN fs.fiscal_year = 2020 THEN fs.product_code END) AS unique_products_2020,
        COUNT(DISTINCT CASE WHEN fs.fiscal_year = 2021 THEN fs.product_code END) AS unique_products_2021
    FROM hardware_fact_sales_monthly AS fs
    JOIN hardware_dim_product AS dp
      ON fs.product_code = dp.product_code
    WHERE fs.fiscal_year IN (2020, 2021)
    GROUP BY dp.segment
)
SELECT
    segment,
    unique_products_2020,
    ROUND(
        (unique_products_2021 - unique_products_2020) * 100.0 / unique_products_2020,
        4
    ) AS pct_increase
FROM segment_counts
WHERE unique_products_2020 > 0
ORDER BY pct_increase DESC, segment;
SELECT
    segment AS product_segment,
    uniq_2020 AS unique_products_2020
FROM (
    SELECT
        dp.segment,
        COUNT(DISTINCT CASE WHEN fs.fiscal_year = 2020 THEN fs.product_code END) AS uniq_2020,
        COUNT(DISTINCT CASE WHEN fs.fiscal_year = 2021 THEN fs.product_code END) AS uniq_2021
    FROM hardware_fact_sales_monthly AS fs
    JOIN hardware_dim_product AS dp
      ON fs.product_code = dp.product_code
    WHERE fs.fiscal_year IN (2020, 2021)
    GROUP BY dp.segment
)
WHERE uniq_2020 > 0
ORDER BY
    1.0 * (uniq_2021 - uniq_2020) / uniq_2020 DESC;
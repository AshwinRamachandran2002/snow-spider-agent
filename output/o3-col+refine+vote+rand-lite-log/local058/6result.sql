WITH yearly_counts AS (
    SELECT 
        p.segment,
        s.fiscal_year,
        COUNT(DISTINCT s.product_code) AS uniq_prod
    FROM hardware_fact_sales_monthly AS s
    JOIN hardware_dim_product        AS p
      ON s.product_code = p.product_code
    WHERE s.fiscal_year IN (2020, 2021)
    GROUP BY p.segment, s.fiscal_year
),
pivot AS (
    SELECT
        segment,
        SUM(CASE WHEN fiscal_year = 2020 THEN uniq_prod END) AS cnt_2020,
        SUM(CASE WHEN fiscal_year = 2021 THEN uniq_prod END) AS cnt_2021
    FROM yearly_counts
    GROUP BY segment
)
SELECT
    segment,
    cnt_2020 AS unique_products_2020
FROM pivot
ORDER BY (cnt_2021 - cnt_2020) * 100.0 / NULLIF(cnt_2020, 0) DESC;
WITH product_segments AS (
    SELECT DISTINCT
        fs.product_code,
        dp.segment,
        fs.fiscal_year
    FROM hardware_fact_sales_monthly AS fs
    JOIN hardware_dim_product      AS dp
      ON dp.product_code = fs.product_code
    WHERE fs.fiscal_year IN (2020, 2021)
),
yearly_counts AS (
    SELECT
        segment,
        fiscal_year,
        COUNT(DISTINCT product_code) AS unique_products
    FROM product_segments
    GROUP BY segment, fiscal_year
),
pivot AS (
    SELECT
        yc20.segment,
        yc20.unique_products AS prod_2020,
        COALESCE(yc21.unique_products, 0) AS prod_2021
    FROM yearly_counts AS yc20
    LEFT JOIN yearly_counts AS yc21
      ON yc20.segment = yc21.segment
     AND yc21.fiscal_year = 2021
    WHERE yc20.fiscal_year = 2020
),
ranked AS (
    SELECT
        segment,
        prod_2020,
        (prod_2021 - prod_2020) * 1.0 / prod_2020 AS pct_increase
    FROM pivot
)
SELECT
    segment,
    prod_2020 AS unique_product_count_2020
FROM ranked
ORDER BY
    pct_increase DESC,
    segment;
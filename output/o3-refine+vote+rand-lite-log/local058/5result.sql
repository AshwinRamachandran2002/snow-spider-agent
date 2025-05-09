WITH base AS (
    /* retain only the years of interest and remove duplicate month rows */
    SELECT DISTINCT product_code,
           fiscal_year
    FROM hardware_fact_sales_monthly
    WHERE fiscal_year IN (2020, 2021)
),
prod_segment AS (
    /* attach each product to its segment */
    SELECT b.fiscal_year,
           p.segment,
           b.product_code
    FROM base b
    JOIN hardware_dim_product p
      ON p.product_code = b.product_code
),
yearly_counts AS (
    /* count unique products by segment and year */
    SELECT segment,
           fiscal_year,
           COUNT(DISTINCT product_code) AS unique_products
    FROM prod_segment
    GROUP BY segment, fiscal_year
),
pivot AS (
    /* pivot the counts so 2020 and 2021 are on the same row */
    SELECT segment,
           MAX(CASE WHEN fiscal_year = 2020 THEN unique_products END) AS products_2020,
           MAX(CASE WHEN fiscal_year = 2021 THEN unique_products END) AS products_2021
    FROM yearly_counts
    GROUP BY segment
),
calc AS (
    /* calculate the percentage increase from 2020 to 2021 */
    SELECT segment,
           products_2020,
           products_2021,
           (products_2021 - products_2020) * 100.0 / products_2020 AS pct_increase
    FROM pivot
    WHERE products_2020 > 0              -- avoid division‑by‑zero cases
)
SELECT segment,
       products_2020 AS unique_products_2020
FROM calc
ORDER BY pct_increase DESC, segment;
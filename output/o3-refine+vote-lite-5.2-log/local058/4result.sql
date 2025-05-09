WITH segment_year_counts AS (
    SELECT
        p.segment,
        f.fiscal_year,
        COUNT(DISTINCT f.product_code) AS unique_products
    FROM hardware_fact_sales_monthly AS f
    JOIN hardware_dim_product       AS p
          ON f.product_code = p.product_code
    WHERE f.fiscal_year IN (2020, 2021)
    GROUP BY p.segment, f.fiscal_year
),
segment_pivot AS (
    SELECT
        segment,
        SUM(CASE WHEN fiscal_year = 2020 THEN unique_products END) AS products_2020,
        SUM(CASE WHEN fiscal_year = 2021 THEN unique_products END) AS products_2021
    FROM segment_year_counts
    GROUP BY segment
),
segment_growth AS (
    SELECT
        segment,
        products_2020,
        products_2021,
        /* percentage increase from 2020 to 2021 */
        CASE
            WHEN products_2020 = 0 OR products_2020 IS NULL THEN NULL
            ELSE (products_2021 - products_2020) * 100.0 / products_2020
        END AS pct_increase
    FROM segment_pivot
)
SELECT
    segment,
    products_2020 AS unique_product_count_2020
FROM segment_growth
WHERE products_2020 IS NOT NULL            -- keep only segments with 2020 sales
ORDER BY
    pct_increase DESC,                     -- highest growth first
    segment;                               -- tie‑breaker
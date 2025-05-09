WITH segment_counts AS (
    SELECT
        hdp.segment,
        COUNT(DISTINCT CASE WHEN hfs.fiscal_year = 2020 THEN hfs.product_code END) AS products_2020,
        COUNT(DISTINCT CASE WHEN hfs.fiscal_year = 2021 THEN hfs.product_code END) AS products_2021
    FROM hardware_fact_sales_monthly AS hfs
    JOIN hardware_dim_product      AS hdp
      ON hdp.product_code = hfs.product_code
    WHERE hfs.fiscal_year IN (2020, 2021)
    GROUP BY hdp.segment
),
percent_growth AS (
    SELECT
        segment,
        products_2020,
        products_2021,
        CASE
            WHEN products_2020 = 0 THEN NULL
            ELSE (products_2021 - products_2020) * 100.0 / products_2020
        END AS pct_increase
    FROM segment_counts
    WHERE products_2020 > 0          -- keep segments that had sales in 2020
)
SELECT
    segment,
    products_2020 AS unique_products_2020
FROM percent_growth
ORDER BY pct_increase DESC;
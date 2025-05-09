WITH
p2020 AS (
    SELECT dp.segment                             AS product_segment,
           COUNT(DISTINCT hf.product_code)        AS unique_products_2020
    FROM   hardware_fact_sales_monthly AS hf
    JOIN   hardware_dim_product        AS dp
           ON hf.product_code = dp.product_code
    WHERE  hf.fiscal_year = 2020
    GROUP  BY dp.segment
),
p2021 AS (
    SELECT dp.segment                             AS product_segment,
           COUNT(DISTINCT hf.product_code)        AS unique_products_2021
    FROM   hardware_fact_sales_monthly AS hf
    JOIN   hardware_dim_product        AS dp
           ON hf.product_code = dp.product_code
    WHERE  hf.fiscal_year = 2021
    GROUP  BY dp.segment
),
growth AS (
    SELECT  p2020.product_segment,
            p2020.unique_products_2020,
            COALESCE(p2021.unique_products_2021,0) AS unique_products_2021,
            (COALESCE(p2021.unique_products_2021,0) - p2020.unique_products_2020) * 1.0
            / p2020.unique_products_2020           AS pct_increase
    FROM    p2020
    LEFT JOIN p2021
           ON p2020.product_segment = p2021.product_segment
)
SELECT  product_segment,
        unique_products_2020
FROM    growth
ORDER BY pct_increase DESC;
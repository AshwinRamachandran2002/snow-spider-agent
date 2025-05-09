WITH c20 AS (
    SELECT dp.segment,
           COUNT(DISTINCT s.product_code) AS unique_products_2020
    FROM hardware_fact_sales_monthly AS s
    JOIN hardware_dim_product        AS dp
         ON s.product_code = dp.product_code
    WHERE s.fiscal_year = 2020
    GROUP BY dp.segment
),
c21 AS (
    SELECT dp.segment,
           COUNT(DISTINCT s.product_code) AS unique_products_2021
    FROM hardware_fact_sales_monthly AS s
    JOIN hardware_dim_product        AS dp
         ON s.product_code = dp.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY dp.segment
)
SELECT  seg.segment,
        COALESCE(c20.unique_products_2020, 0) AS unique_products_2020
FROM   (SELECT DISTINCT segment FROM hardware_dim_product) AS seg
LEFT   JOIN c20 ON seg.segment = c20.segment
LEFT   JOIN c21 ON seg.segment = c21.segment
ORDER  BY
        CASE
             WHEN COALESCE(c20.unique_products_2020, 0) = 0 THEN -1
             ELSE (COALESCE(c21.unique_products_2021, 0) - COALESCE(c20.unique_products_2020, 0))
                  * 1.0 / COALESCE(c20.unique_products_2020, 0)
        END DESC;
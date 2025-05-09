WITH prod_counts AS (
    SELECT 
        p.segment,
        s.fiscal_year,
        COUNT(DISTINCT s.product_code) AS unique_products
    FROM hardware_fact_sales_monthly AS s
    JOIN hardware_dim_product       AS p 
      ON p.product_code = s.product_code
    WHERE s.fiscal_year IN (2020, 2021)
    GROUP BY p.segment, s.fiscal_year
),
pivot AS (
    SELECT 
        c20.segment,
        c20.unique_products AS products_2020,
        COALESCE(c21.unique_products, 0) AS products_2021
    FROM prod_counts AS c20
    LEFT JOIN prod_counts AS c21
           ON c21.segment     = c20.segment
          AND c21.fiscal_year = 2021
    WHERE c20.fiscal_year = 2020
)
SELECT 
    segment,
    products_2020
FROM pivot
ORDER BY 
    CASE 
        WHEN products_2020 = 0 THEN -99999          -- avoid divide-by-zero, push to bottom
        ELSE (products_2021 - products_2020) * 1.0 / products_2020
    END DESC;
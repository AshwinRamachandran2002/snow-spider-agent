WITH sales_2020 AS (
    SELECT p.segment,
           COUNT(DISTINCT f.product_code) AS cnt2020
    FROM hardware_fact_sales_monthly AS f
    JOIN hardware_dim_product        AS p
      ON f.product_code = p.product_code
    WHERE f.fiscal_year = 2020
    GROUP BY p.segment
),
sales_2021 AS (
    SELECT p.segment,
           COUNT(DISTINCT f.product_code) AS cnt2021
    FROM hardware_fact_sales_monthly AS f
    JOIN hardware_dim_product        AS p
      ON f.product_code = p.product_code
    WHERE f.fiscal_year = 2021
    GROUP BY p.segment
),
combined AS (
    SELECT s20.segment,
           s20.cnt2020,
           COALESCE(s21.cnt2021, 0) AS cnt2021,
           (COALESCE(s21.cnt2021, 0) - s20.cnt2020) * 1.0 / s20.cnt2020 AS pct_increase
    FROM sales_2020 AS s20
    LEFT JOIN sales_2021 AS s21
      ON s20.segment = s21.segment
)
SELECT segment,
       cnt2020 AS unique_product_count_2020
FROM combined
ORDER BY pct_increase DESC,
         segment;
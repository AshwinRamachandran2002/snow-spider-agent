WITH sales_2021 AS (
    SELECT 
        p.division,
        s.product_code,
        SUM(s.sold_quantity) AS total_quantity
    FROM hardware_fact_sales_monthly AS s
    JOIN hardware_dim_product      AS p
         ON s.product_code = p.product_code
    WHERE s.date >= '2021-01-01'
      AND s.date <  '2022-01-01'          -- calendar year 2021
    GROUP BY p.division, s.product_code
),
ranked AS (
    SELECT
        division,
        product_code,
        total_quantity,
        RANK() OVER (PARTITION BY division 
                     ORDER BY total_quantity DESC) AS rnk
    FROM sales_2021
),
top3 AS (
    SELECT
        division,
        total_quantity
    FROM ranked
    WHERE rnk <= 3                       -- top‑3 products per division
)
SELECT
    division,
    ROUND(AVG(total_quantity), 4) AS avg_quantity_sold   -- overall average of top‑3 totals
FROM top3
GROUP BY division
ORDER BY division;
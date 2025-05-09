WITH sales_2021 AS (
    SELECT
        p.division,
        s.product_code,
        SUM(s.sold_quantity) AS total_qty
    FROM hardware_fact_sales_monthly AS s
    JOIN hardware_dim_product        AS p
         ON s.product_code = p.product_code
    WHERE s.date BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p.division, s.product_code
),
ranked AS (
    SELECT
        division,
        product_code,
        total_qty,
        DENSE_RANK() OVER (PARTITION BY division ORDER BY total_qty DESC, product_code) AS rnk
    FROM sales_2021
),
top_three AS (
    SELECT
        division,
        total_qty
    FROM ranked
    WHERE rnk <= 3
)
SELECT
    division,
    ROUND(AVG(total_qty), 4) AS avg_quantity_sold
FROM top_three
GROUP BY division
ORDER BY division;
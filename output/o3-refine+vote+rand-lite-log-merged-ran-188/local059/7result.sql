WITH sales_2021 AS (
    /* total quantity sold per product (calendar year 2021) */
    SELECT  p.division,
            s.product_code,
            SUM(s.sold_quantity) AS total_quantity
    FROM hardware_fact_sales_monthly AS s
    JOIN hardware_dim_product      AS p
         ON s.product_code = p.product_code
    WHERE s.date BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p.division, s.product_code
),
ranked AS (
    /* rank products within each division by quantity sold */
    SELECT  division,
            product_code,
            total_quantity,
            ROW_NUMBER() OVER (
                PARTITION BY division
                ORDER BY total_quantity DESC, product_code
            ) AS rn
    FROM sales_2021
),
top3 AS (
    /* keep only the three best‑selling products per division */
    SELECT division, total_quantity
    FROM ranked
    WHERE rn <= 3
)
SELECT  division,
        AVG(total_quantity) AS average_quantity_sold
FROM top3
GROUP BY division
ORDER BY division;
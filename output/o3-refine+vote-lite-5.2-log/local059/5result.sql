WITH sales_2021 AS (
    SELECT 
        s.product_code,
        s.sold_quantity,
        s.date
    FROM hardware_fact_sales_monthly AS s
    WHERE s.date BETWEEN '2021-01-01' AND '2021-12-31'
),
product_sales AS (
    SELECT
        p.division,
        s.product_code,
        SUM(s.sold_quantity) AS total_quantity
    FROM sales_2021 AS s
    JOIN hardware_dim_product AS p
        ON p.product_code = s.product_code
    GROUP BY
        p.division,
        s.product_code
),
ranked_products AS (
    SELECT
        division,
        product_code,
        total_quantity,
        ROW_NUMBER() OVER (
            PARTITION BY division
            ORDER BY total_quantity DESC
        ) AS rn
    FROM product_sales
),
top_three AS (
    SELECT
        division,
        total_quantity
    FROM ranked_products
    WHERE rn <= 3
)
SELECT
    division,
    AVG(total_quantity) AS avg_quantity_sold
FROM top_three
GROUP BY
    division
ORDER BY
    division;
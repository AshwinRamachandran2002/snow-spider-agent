WITH sales_2021 AS (
    -- all sales that happened in the calendar year 2021
    SELECT
        product_code,
        sold_quantity
    FROM hardware_fact_sales_monthly
    WHERE date BETWEEN '2021-01-01' AND '2021-12-31'
),
product_sales AS (
    -- total quantity sold in 2021 for every product within its division
    SELECT
        p.division,
        s.product_code,
        SUM(s.sold_quantity) AS total_qty
    FROM sales_2021   AS s
    JOIN hardware_dim_product AS p
      ON p.product_code = s.product_code
    GROUP BY
        p.division,
        s.product_code
),
ranked AS (
    -- rank products within each division by total quantity
    SELECT
        division,
        product_code,
        total_qty,
        RANK() OVER (PARTITION BY division ORDER BY total_qty DESC) AS rnk
    FROM product_sales
),
top3 AS (
    -- keep only the three best‑selling products per division
    SELECT
        division,
        total_qty
    FROM ranked
    WHERE rnk <= 3
)
-- overall average quantity sold of those top‑3 products in each division
SELECT
    division,
    ROUND(AVG(total_qty), 4) AS avg_quantity_top3
FROM top3
GROUP BY division
ORDER BY division;
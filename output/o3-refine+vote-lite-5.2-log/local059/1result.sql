WITH sales_2021 AS (
    -- all sales that occurred in calendar year 2021
    SELECT
        product_code,
        sold_quantity
    FROM
        hardware_fact_sales_monthly
    WHERE
        substr(date, 1, 4) = '2021'
),
prod_totals AS (
    -- total quantity sold per product in 2021
    SELECT
        product_code,
        SUM(sold_quantity) AS total_qty
    FROM
        sales_2021
    GROUP BY
        product_code
),
div_prod_sales AS (
    -- attach each product to its division
    SELECT
        p.division,
        t.product_code,
        t.total_qty
    FROM
        prod_totals AS t
        JOIN hardware_dim_product AS p
          ON p.product_code = t.product_code
),
ranked AS (
    -- rank products by quantity within each division
    SELECT
        division,
        product_code,
        total_qty,
        ROW_NUMBER() OVER (
            PARTITION BY division
            ORDER BY total_qty DESC, product_code
        ) AS rn
    FROM
        div_prod_sales
),
top3 AS (
    -- keep only the top‑three products per division
    SELECT
        division,
        total_qty
    FROM
        ranked
    WHERE
        rn <= 3
)
-- overall average quantity sold of the top three products in each division
SELECT
    division,
    ROUND(AVG(total_qty), 4) AS avg_quantity_sold
FROM
    top3
GROUP BY
    division
ORDER BY
    division;
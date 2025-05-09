WITH sales_2021 AS (
    SELECT
        p.division,
        s.product_code,
        SUM(s.sold_quantity) AS total_qty
    FROM "hardware_fact_sales_monthly" AS s
    JOIN "hardware_dim_product"        AS p
          ON s.product_code = p.product_code
    WHERE substr(s.date, 1, 4) = '2021'          -- calendar year 2021
    GROUP BY p.division, s.product_code
),
ranked AS (
    SELECT
        division,
        product_code,
        total_qty,
        ROW_NUMBER() OVER (
            PARTITION BY division
            ORDER BY total_qty DESC, product_code
        ) AS rn
    FROM sales_2021
),
top3 AS (
    SELECT
        division,
        total_qty
    FROM ranked
    WHERE rn <= 3                              -- top‑3 best‑selling products
)
SELECT
    division,
    AVG(total_qty) AS avg_quantity_top3        -- overall average quantity sold
FROM top3
GROUP BY division
ORDER BY division;
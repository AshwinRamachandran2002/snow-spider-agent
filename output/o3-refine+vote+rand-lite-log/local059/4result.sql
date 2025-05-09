WITH sales_2021 AS (
    -- total quantity sold per product in calendar year 2021
    SELECT
        p."division",
        s."product_code",
        SUM(s."sold_quantity") AS total_sold
    FROM "hardware_fact_sales_monthly" AS s
    JOIN "hardware_dim_product"       AS p
          ON s."product_code" = p."product_code"
    WHERE s."date" BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p."division", s."product_code"
),
ranked AS (
    -- rank products by quantity sold within each division
    SELECT
        division,
        product_code,
        total_sold,
        RANK() OVER (PARTITION BY division ORDER BY total_sold DESC) AS rnk
    FROM sales_2021
),
top3 AS (
    -- keep only the top‑three products per division
    SELECT division, total_sold
    FROM ranked
    WHERE rnk <= 3
)
-- overall average quantity sold of those top‑three products
SELECT
    division,
    ROUND(AVG(total_sold), 4) AS avg_quantity_sold
FROM top3
GROUP BY division
ORDER BY division;
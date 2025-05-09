WITH sales_2021 AS (
    SELECT
        p.division,
        h.product_code,
        SUM(h.sold_quantity) AS total_qty
    FROM hardware_fact_sales_monthly AS h
    JOIN hardware_dim_product       AS p
      ON h.product_code = p.product_code
    WHERE substr(h."date", 1, 4) = '2021'
    GROUP BY p.division, h.product_code
),
ranked AS (
    SELECT
        division,
        product_code,
        total_qty,
        ROW_NUMBER() OVER (PARTITION BY division
                           ORDER BY total_qty DESC) AS rn
    FROM sales_2021
)
SELECT
    division,
    AVG(total_qty) AS avg_top3_qty
FROM ranked
WHERE rn <= 3
GROUP BY division
ORDER BY division;
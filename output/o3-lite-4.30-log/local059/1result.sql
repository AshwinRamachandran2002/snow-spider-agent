WITH product_totals AS (
    SELECT
        p.division,
        h.product_code,
        SUM(h.sold_quantity) AS total_qty
    FROM hardware_fact_sales_monthly AS h
    JOIN hardware_dim_product AS p
      ON p.product_code = h.product_code
    WHERE h.date BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p.division, h.product_code
),
ranked_products AS (
    SELECT
        division,
        product_code,
        total_qty,
        RANK() OVER (PARTITION BY division ORDER BY total_qty DESC) AS rnk
    FROM product_totals
)
SELECT
    division,
    ROUND(AVG(total_qty), 4) AS average_quantity_sold
FROM ranked_products
WHERE rnk <= 3
GROUP BY division;
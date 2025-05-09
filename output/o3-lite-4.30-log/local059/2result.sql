WITH product_totals AS (
    SELECT p.division,
           s.product_code,
           SUM(s.sold_quantity) AS total_qty
    FROM hardware_fact_sales_monthly AS s
    JOIN hardware_dim_product        AS p
      ON s.product_code = p.product_code
    WHERE strftime('%Y', s.date) = '2021'
    GROUP BY p.division, s.product_code
),
ranked AS (
    SELECT division,
           product_code,
           total_qty,
           ROW_NUMBER() OVER (PARTITION BY division ORDER BY total_qty DESC) AS rnk
    FROM product_totals
)
SELECT division,
       printf('%.4f', AVG(total_qty)) AS average_quantity_sold
FROM ranked
WHERE rnk <= 3
GROUP BY division
ORDER BY division;
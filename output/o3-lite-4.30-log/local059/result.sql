SELECT
    sub.division,
    printf('%.4f', AVG(sub.total_qty)) AS average_quantity_sold
FROM (
    SELECT
        p.division,
        SUM(f.sold_quantity) AS total_qty,
        ROW_NUMBER() OVER (
            PARTITION BY p.division
            ORDER BY SUM(f.sold_quantity) DESC
        ) AS rn
    FROM hardware_fact_sales_monthly AS f
    JOIN hardware_dim_product       AS p
      ON f.product_code = p.product_code
    WHERE f.date BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p.division, f.product_code
) AS sub
WHERE sub.rn <= 3
GROUP BY sub.division
ORDER BY sub.division;
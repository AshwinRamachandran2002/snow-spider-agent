WITH annual_qty AS (
    SELECT product_id,
           SUM(qty) AS year_qty
    FROM monthly_sales
    WHERE product_id IN (4160, 7790)
      AND mth BETWEEN '2018-01-01' AND '2018-12-01'
    GROUP BY product_id
)
SELECT ROUND(AVG(year_qty),4) AS avg_forecasted_annual_sales_2018
FROM annual_qty;
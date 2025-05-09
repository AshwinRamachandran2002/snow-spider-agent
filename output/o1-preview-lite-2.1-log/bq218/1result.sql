SELECT
  s.item_number,
  s.item_description,
  ROUND(
    ((SUM(CASE WHEN EXTRACT(YEAR FROM s.date) = 2023 THEN s.sale_dollars ELSE 0 END) - 
      SUM(CASE WHEN EXTRACT(YEAR FROM s.date) = 2022 THEN s.sale_dollars ELSE 0 END)) / 
     SUM(CASE WHEN EXTRACT(YEAR FROM s.date) = 2022 THEN s.sale_dollars ELSE NULL END)) * 100, 4
  ) AS Year_Over_Year_Growth_Percentage
FROM
  `bigquery-public-data.iowa_liquor_sales.sales` s
WHERE
  EXTRACT(YEAR FROM s.date) IN (2022, 2023)
GROUP BY
  s.item_number, s.item_description
HAVING
  SUM(CASE WHEN EXTRACT(YEAR FROM s.date) = 2022 THEN s.sale_dollars ELSE NULL END) > 0
ORDER BY
  Year_Over_Year_Growth_Percentage DESC
LIMIT 5;
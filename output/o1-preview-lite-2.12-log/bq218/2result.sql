SELECT
  item_number AS Item_Number,
  item_description AS Item_Description,
  (
    (
      SUM(CASE WHEN EXTRACT(YEAR FROM date) = 2023 THEN sale_dollars ELSE 0 END) - 
      SUM(CASE WHEN EXTRACT(YEAR FROM date) = 2022 THEN sale_dollars ELSE 0 END)
    ) / SUM(CASE WHEN EXTRACT(YEAR FROM date) = 2022 THEN sale_dollars ELSE NULL END)
  ) * 100 AS Year_Over_Year_Growth_Percentage
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE EXTRACT(YEAR FROM date) IN (2022, 2023)
GROUP BY Item_Number, Item_Description
HAVING SUM(CASE WHEN EXTRACT(YEAR FROM date) = 2022 THEN sale_dollars ELSE 0 END) > 0
ORDER BY Year_Over_Year_Growth_Percentage DESC
LIMIT 5;
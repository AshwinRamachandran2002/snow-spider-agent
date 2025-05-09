SELECT
  `item_number` AS Item_Number,
  `item_description` AS Item_Description,
  ROUND(SAFE_DIVIDE(
    SUM(IF(EXTRACT(YEAR FROM `date`) = 2023, `sale_dollars`, 0)) - SUM(IF(EXTRACT(YEAR FROM `date`) = 2022, `sale_dollars`, 0)),
    SUM(IF(EXTRACT(YEAR FROM `date`) = 2022, `sale_dollars`, NULL))
  ) * 100, 4) AS Year_Over_Year_Growth_Percentage
FROM `bigquery-public-data`.`iowa_liquor_sales`.`sales`
WHERE EXTRACT(YEAR FROM `date`) IN (2022, 2023)
GROUP BY `item_number`, `item_description`
HAVING SUM(IF(EXTRACT(YEAR FROM `date`) = 2022, `sale_dollars`, 0)) > 0
ORDER BY Year_Over_Year_Growth_Percentage DESC, `item_number`
LIMIT 5;
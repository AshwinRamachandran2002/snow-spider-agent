WITH top_categories_2021 AS (
  SELECT
    `category_name`,
    SUM(`sale_dollars`) / SUM(`volume_sold_liters`) AS avg_price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) = 2021
  GROUP BY `category_name`
  ORDER BY avg_price_per_liter DESC
  LIMIT 10
)
SELECT
  `category_name`,
  EXTRACT(YEAR FROM `date`) AS year,
  ROUND(SUM(`sale_dollars`) / SUM(`volume_sold_liters`), 4) AS avg_price_per_liter
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE EXTRACT(YEAR FROM `date`) IN (2019, 2020, 2021)
  AND `category_name` IN (
    SELECT `category_name` FROM top_categories_2021
  )
GROUP BY `category_name`, year
ORDER BY `category_name`, year;
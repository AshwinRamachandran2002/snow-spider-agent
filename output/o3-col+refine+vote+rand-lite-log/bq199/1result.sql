/* Top-10 2021 categories by average per-liter retail price
   and their corresponding 2019–2021 averages                */
WITH top_2021 AS (
  SELECT
    category_name
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) = 2021
  GROUP BY category_name
  ORDER BY AVG(state_bottle_retail * 1000.0 / bottle_volume_ml) DESC
  LIMIT 10
)
SELECT
  category_name,
  AVG(CASE WHEN EXTRACT(YEAR FROM `date`) = 2019
           THEN state_bottle_retail * 1000.0 / bottle_volume_ml END) AS avg_retail_per_liter_2019,
  AVG(CASE WHEN EXTRACT(YEAR FROM `date`) = 2020
           THEN state_bottle_retail * 1000.0 / bottle_volume_ml END) AS avg_retail_per_liter_2020,
  AVG(CASE WHEN EXTRACT(YEAR FROM `date`) = 2021
           THEN state_bottle_retail * 1000.0 / bottle_volume_ml END) AS avg_retail_per_liter_2021
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE EXTRACT(YEAR FROM `date`) IN (2019, 2020, 2021)
  AND category_name IN (SELECT category_name FROM top_2021)
GROUP BY category_name
ORDER BY avg_retail_per_liter_2021 DESC;
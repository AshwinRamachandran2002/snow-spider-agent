WITH item_sales AS (
  SELECT
    item_description,
    SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2022 THEN sale_dollars END) AS sales_2022,
    SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2023 THEN sale_dollars END) AS sales_2023
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE sale_dollars > 0
    AND EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_description
)
SELECT
  item_description,
  ROUND(sales_2022, 2) AS sales_2022,
  ROUND(sales_2023, 2) AS sales_2023,
  ROUND((sales_2023 - sales_2022) / sales_2022 * 100, 2) AS yoy_pct_growth
FROM item_sales
WHERE sales_2022 > 0
ORDER BY yoy_pct_growth DESC
LIMIT 5;
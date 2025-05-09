-- Top 5 items with the highest YoY growth in total sales revenue (2023 vs. 2022)
WITH sales_2022 AS (
  SELECT
    item_number,
    item_description,
    SUM(sale_dollars) AS total_2022_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) = 2022
  GROUP BY item_number, item_description
),
sales_2023 AS (
  SELECT
    item_number,
    item_description,
    SUM(sale_dollars) AS total_2023_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) = 2023
  GROUP BY item_number, item_description
)
SELECT
  a.item_number,
  a.item_description,
  a.total_2022_sales,
  b.total_2023_sales,
  ROUND(100 * (b.total_2023_sales - a.total_2022_sales) / a.total_2022_sales, 2) AS yoy_growth_pct
FROM sales_2022 a
JOIN sales_2023 b
  ON a.item_number = b.item_number
WHERE a.total_2022_sales > 0         -- avoid divide-by-zero
  AND b.total_2023_sales > 0         -- ensure positive growth
ORDER BY yoy_growth_pct DESC
LIMIT 5;
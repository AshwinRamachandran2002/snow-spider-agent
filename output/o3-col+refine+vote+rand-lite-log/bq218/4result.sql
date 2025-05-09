WITH sales_by_item AS (
  SELECT
    item_number,
    item_description,
    SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2022 THEN sale_dollars END) AS sales_2022,
    SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2023 THEN sale_dollars END) AS sales_2023
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_number, item_description
),
growth AS (
  SELECT
    item_number,
    item_description,
    sales_2022,
    sales_2023,
    SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100 AS growth_pct
  FROM sales_by_item
  WHERE sales_2022 > 0            -- avoid divide-by-zero and ensure meaningful baseline
)
SELECT
  item_number,
  item_description,
  ROUND(sales_2022, 2) AS sales_2022,
  ROUND(sales_2023, 2) AS sales_2023,
  ROUND(growth_pct, 2) AS growth_pct
FROM growth
ORDER BY growth_pct DESC
LIMIT 5;
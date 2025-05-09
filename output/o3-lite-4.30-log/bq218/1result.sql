WITH sales_per_item_year AS (
  SELECT
    item_number,
    ANY_VALUE(item_description) AS item_description,
    EXTRACT(YEAR FROM `date`)   AS sales_year,
    SUM(sale_dollars)           AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_number, sales_year
),
pivot AS (
  SELECT
    item_number,
    MAX(item_description)                                        AS item_name,
    MAX(CASE WHEN sales_year = 2022 THEN total_sales END) AS sales_2022,
    MAX(CASE WHEN sales_year = 2023 THEN total_sales END) AS sales_2023
  FROM sales_per_item_year
  GROUP BY item_number
)
SELECT
  item_number                     AS item_id,
  item_name,
  ROUND(
    SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100, 4
  )                               AS yoy_growth_percentage
FROM pivot
WHERE sales_2022 > 0
ORDER BY yoy_growth_percentage DESC, item_id
LIMIT 5;
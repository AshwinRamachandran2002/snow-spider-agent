WITH yearly_item_sales AS (
  SELECT
    item_number,
    item_description,
    SUM(CASE WHEN EXTRACT(YEAR FROM date) = 2022 THEN sale_dollars END) AS sales_2022,
    SUM(CASE WHEN EXTRACT(YEAR FROM date) = 2023 THEN sale_dollars END) AS sales_2023
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM date) IN (2022, 2023)
  GROUP BY item_number, item_description
)
SELECT
  item_number      AS item_id,
  item_description AS item_name,
  ROUND(
    SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100,
    4
  )                AS yoy_growth_percentage
FROM yearly_item_sales
WHERE sales_2022 > 0
  AND sales_2023 IS NOT NULL
ORDER BY
  yoy_growth_percentage DESC,
  item_name
LIMIT 5;
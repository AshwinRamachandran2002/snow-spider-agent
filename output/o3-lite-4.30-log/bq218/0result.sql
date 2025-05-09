WITH yearly_sales AS (
  SELECT
    item_number,
    item_description,
    EXTRACT(YEAR FROM `date`) AS yr,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_number, item_description, yr
),
pivot AS (
  SELECT
    item_number,
    item_description,
    SUM(CASE WHEN yr = 2022 THEN total_sales END) AS sales_2022,
    SUM(CASE WHEN yr = 2023 THEN total_sales END) AS sales_2023
  FROM yearly_sales
  GROUP BY item_number, item_description
)
SELECT
  item_number   AS item_id,
  item_description AS item_name,
  ROUND(
    SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100,
    4
  )             AS yoy_growth_percentage
FROM pivot
WHERE sales_2022 > 0        -- ensure a valid base for the growth calculation
ORDER BY yoy_growth_percentage DESC, item_id
LIMIT 5;
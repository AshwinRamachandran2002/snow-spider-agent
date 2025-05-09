-- Top 5 items with the highest year‑over‑year growth rate in total sales revenue (2023 vs. 2022)
WITH yearly_sales AS (
  SELECT
    item_number,
    item_description,
    EXTRACT(YEAR FROM `date`) AS sales_year,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_number, item_description, sales_year
),
pivot AS (
  SELECT
    item_number,
    item_description,
    SUM(CASE WHEN sales_year = 2022 THEN total_sales END) AS sales_2022,
    SUM(CASE WHEN sales_year = 2023 THEN total_sales END) AS sales_2023
  FROM yearly_sales
  GROUP BY item_number, item_description
)
SELECT
  item_number,
  item_description,
  sales_2022,
  sales_2023,
  ROUND( SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100 , 4) AS yoy_growth_pct
FROM pivot
WHERE sales_2022 > 0              -- avoid division by zero / meaningless growth
  AND sales_2023 IS NOT NULL
ORDER BY yoy_growth_pct DESC, item_number
LIMIT 5;
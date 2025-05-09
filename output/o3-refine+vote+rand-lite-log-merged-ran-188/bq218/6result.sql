-- Top 5 items with the highest YoY (%) growth in total sales revenue for 2023
WITH sales_by_year AS (
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
    MAX(item_description) AS item_description,
    SUM(CASE WHEN yr = 2022 THEN total_sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN yr = 2023 THEN total_sales ELSE 0 END) AS sales_2023
  FROM sales_by_year
  GROUP BY item_number
),
growth AS (
  SELECT
    item_number,
    item_description,
    sales_2022,
    sales_2023,
    SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100 AS yoy_growth_pct
  FROM pivot
  WHERE sales_2022 > 0             -- exclude items with no 2022 sales to avoid divide‑by‑zero
)
SELECT
  item_number,
  item_description,
  sales_2022,
  sales_2023,
  yoy_growth_pct
FROM growth
ORDER BY yoy_growth_pct DESC, item_number
LIMIT 5;
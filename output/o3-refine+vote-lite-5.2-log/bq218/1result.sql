-- Top 5 items with the highest year‑over‑year growth in total sales revenue (2023 vs 2022)
WITH item_yearly AS (
  SELECT
    item_number,
    ANY_VALUE(item_description) AS item_description,
    EXTRACT(YEAR FROM `date`) AS yr,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_number, yr
),
item_pivot AS (
  SELECT
    item_number,
    item_description,
    SUM(CASE WHEN yr = 2022 THEN total_sales END) AS sales_2022,
    SUM(CASE WHEN yr = 2023 THEN total_sales END) AS sales_2023
  FROM item_yearly
  GROUP BY item_number, item_description
),
item_growth AS (
  SELECT
    item_number,
    item_description,
    sales_2022,
    sales_2023,
    (sales_2023 - sales_2022) / sales_2022 * 100 AS yoy_growth_pct
  FROM item_pivot
  WHERE sales_2022 > 0          -- avoid divide‑by‑zero and require prior‑year sales
)
SELECT
  item_number,
  item_description,
  sales_2022,
  sales_2023,
  ROUND(yoy_growth_pct, 4) AS yoy_growth_percentage
FROM item_growth
ORDER BY yoy_growth_pct DESC, item_number
LIMIT 5;
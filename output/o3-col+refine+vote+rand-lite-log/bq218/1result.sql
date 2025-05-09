-- Top 5 items with the highest YoY % growth in total sales revenue for 2023
WITH yearly_sales AS (
  SELECT
    item_number,
    item_description,
    EXTRACT(YEAR FROM `date`) AS yr,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE sale_dollars > 0                      -- ignore returns/credits
    AND EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_number, item_description, yr
),
sales_pivot AS (
  SELECT
    item_number,
    item_description,
    MAX(IF(yr = 2022, total_sales, NULL)) AS sales_2022,
    MAX(IF(yr = 2023, total_sales, NULL)) AS sales_2023
  FROM yearly_sales
  GROUP BY item_number, item_description
),
growth AS (
  SELECT
    item_number,
    item_description,
    sales_2022,
    sales_2023,
    SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100 AS yoy_pct_growth
  FROM sales_pivot
  WHERE sales_2022 > 0            -- must have sales in 2022 to compute growth
)
SELECT
  item_number,
  item_description,
  ROUND(sales_2022, 2) AS sales_2022,
  ROUND(sales_2023, 2) AS sales_2023,
  ROUND(yoy_pct_growth, 2) AS yoy_pct_growth
FROM growth
ORDER BY yoy_pct_growth DESC
LIMIT 5;
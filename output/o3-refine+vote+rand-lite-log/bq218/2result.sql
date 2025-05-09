-- Top 5 items with the highest YoY growth (2022 ➜ 2023) in total sales revenue
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
pivot_sales AS (
  SELECT
    item_number,
    ANY_VALUE(item_description) AS item_description,
    SUM(CASE WHEN sales_year = 2022 THEN total_sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN sales_year = 2023 THEN total_sales ELSE 0 END) AS sales_2023
  FROM yearly_sales
  GROUP BY item_number
),
growth_calc AS (
  SELECT
    item_number,
    item_description,
    sales_2022,
    sales_2023,
    SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100 AS growth_pct
  FROM pivot_sales
  WHERE sales_2022 > 0            -- exclude items with no 2022 sales to avoid infinite growth
)
SELECT
  item_number,
  item_description,
  ROUND(sales_2022, 2) AS sales_2022,
  ROUND(sales_2023, 2) AS sales_2023,
  ROUND(growth_pct, 4) AS growth_percentage
FROM growth_calc
ORDER BY growth_pct DESC, item_number
LIMIT 5;
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
sales_pivot AS (
  SELECT
    item_number,
    ANY_VALUE(item_description) AS item_description,
    SUM(CASE WHEN yr = 2022 THEN total_sales END) AS sales_2022,
    SUM(CASE WHEN yr = 2023 THEN total_sales END) AS sales_2023
  FROM yearly_sales
  GROUP BY item_number
),
growth_calc AS (
  SELECT
    item_number,
    item_description,
    sales_2022,
    sales_2023,
    SAFE_CAST(ROUND(
      (sales_2023 - sales_2022) / sales_2022 * 100, 
    4) AS FLOAT64) AS growth_pct
  FROM sales_pivot
  WHERE sales_2022 > 0
)

SELECT
  item_number,
  item_description,
  sales_2022,
  sales_2023,
  growth_pct
FROM growth_calc
ORDER BY growth_pct DESC, item_number
LIMIT 5;
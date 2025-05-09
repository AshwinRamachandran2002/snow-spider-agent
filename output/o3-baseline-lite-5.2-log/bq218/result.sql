WITH yearly_sales AS (
  SELECT
    item_number,
    item_description,
    EXTRACT(YEAR FROM `date`) AS yr,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE sale_dollars > 0                  -- ignore returns / negative sales
    AND EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_number, item_description, yr
),
pivot AS (
  SELECT
    item_number,
    item_description,
    SUM(IF(yr = 2022, total_sales, 0)) AS sales_2022,
    SUM(IF(yr = 2023, total_sales, 0)) AS sales_2023
  FROM yearly_sales
  GROUP BY item_number, item_description
),
growth AS (
  SELECT
    item_number,
    item_description,
    sales_2022,
    sales_2023,
    SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100 AS yoy_growth_pct
  FROM pivot
  WHERE sales_2022 > 0                    -- ensure a valid baseline for % growth
)
SELECT
  item_number,
  item_description,
  ROUND(yoy_growth_pct, 4) AS yoy_growth_percentage
FROM growth
ORDER BY yoy_growth_pct DESC, item_number
LIMIT 5;
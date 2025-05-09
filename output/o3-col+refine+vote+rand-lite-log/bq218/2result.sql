WITH yearly_sales AS (
  -- aggregate positive sales for 2022 and 2023
  SELECT
    item_number,
    item_description,
    EXTRACT(YEAR FROM `date`) AS yr,
    SUM(sale_dollars) AS sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE sale_dollars > 0
    AND EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_number, item_description, yr
),
yoy AS (
  -- join 2023 vs 2022 and keep items with ≥ $10K in 2022 sales
  SELECT
    a.item_number,
    a.item_description,
    b.sales AS sales_2022,
    a.sales AS sales_2023,
    SAFE_DIVIDE(a.sales - b.sales, b.sales) AS yoy_growth_pct
  FROM yearly_sales a
  JOIN yearly_sales b
    ON a.item_number = b.item_number
   AND a.yr = 2023
   AND b.yr = 2022
  WHERE b.sales >= 10000
)
SELECT
  item_number,
  item_description,
  sales_2022,
  sales_2023,
  ROUND(yoy_growth_pct * 100, 2) AS yoy_growth_percentage
FROM yoy
ORDER BY yoy_growth_pct DESC
LIMIT 5;
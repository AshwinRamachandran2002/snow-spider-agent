WITH yearly AS (
  SELECT
    item_description,
    EXTRACT(YEAR FROM `date`) AS yr,
    SUM(sale_dollars)        AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_description, yr
),
pivot AS (
  SELECT
    item_description,
    SUM(CASE WHEN yr = 2022 THEN total_sales END) AS sales_2022,
    SUM(CASE WHEN yr = 2023 THEN total_sales END) AS sales_2023
  FROM yearly
  GROUP BY item_description
)
SELECT
  item_description,
  sales_2022,
  sales_2023,
  SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) AS yoy_growth_pct
FROM pivot
WHERE sales_2022 > 0   -- require a positive baseline in 2022
      AND sales_2023 IS NOT NULL
ORDER BY yoy_growth_pct DESC
LIMIT 5;
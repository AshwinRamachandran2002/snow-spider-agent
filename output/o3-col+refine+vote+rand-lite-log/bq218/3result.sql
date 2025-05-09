WITH item_year_sales AS (
  SELECT
    item_description,
    EXTRACT(YEAR FROM `date`) AS sales_year,
    SUM(sale_dollars)        AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) IN (2022, 2023)
  GROUP BY item_description, sales_year
),
pivot_sales AS (
  SELECT
    item_description,
    SUM(CASE WHEN sales_year = 2022 THEN total_sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN sales_year = 2023 THEN total_sales ELSE 0 END) AS sales_2023
  FROM item_year_sales
  GROUP BY item_description
)
SELECT
  item_description,
  sales_2022,
  sales_2023,
  SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100 AS yoy_growth_pct
FROM pivot_sales
WHERE sales_2022 > 0          -- exclude items with no 2022 sales or only returns
  AND sales_2023 > 0          -- keep items that actually sold in 2023
ORDER BY yoy_growth_pct DESC
LIMIT 5;
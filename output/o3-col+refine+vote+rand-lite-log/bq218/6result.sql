-- Top 5 items with the highest YoY % growth in total sales revenue (2023 vs 2022)
WITH item_sales AS (
  SELECT
    item_number,
    ANY_VALUE(item_description) AS item_description,
    SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2022 THEN sale_dollars END) AS sales_2022,
    SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2023 THEN sale_dollars END) AS sales_2023
  FROM
    `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
    EXTRACT(YEAR FROM `date`) IN (2022, 2023)
    AND sale_dollars > 0              -- exclude returns / negative sales
  GROUP BY
    item_number
)
SELECT
  item_number,
  item_description,
  sales_2022,
  sales_2023,
  SAFE_DIVIDE(sales_2023 - sales_2022, sales_2022) * 100 AS growth_pct
FROM
  item_sales
WHERE
  sales_2022 IS NOT NULL
  AND sales_2023 IS NOT NULL
ORDER BY
  growth_pct DESC
LIMIT 5;
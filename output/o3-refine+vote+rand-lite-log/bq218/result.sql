-- Top 5 items with the highest year‑over‑year (2022 → 2023) growth 
-- in total sales revenue
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
pivot_sales AS (
  SELECT
    item_number,
    item_description,
    SUM(CASE WHEN yr = 2022 THEN total_sales END) AS sales_2022,
    SUM(CASE WHEN yr = 2023 THEN total_sales END) AS sales_2023
  FROM yearly_sales
  GROUP BY item_number, item_description
),
growth AS (
  SELECT
    item_number,
    item_description,
    sales_2022,
    sales_2023,
    (sales_2023 - sales_2022) / sales_2022 * 100 AS yoy_growth_pct
  FROM pivot_sales
  WHERE sales_2022 > 0      -- avoid divide‑by‑zero or negative‑base anomalies
    AND sales_2023 IS NOT NULL
)
SELECT
  item_number,
  item_description,
  ROUND(yoy_growth_pct, 4) AS yoy_growth_pct
FROM growth
WHERE yoy_growth_pct > 0      -- only positive growth
ORDER BY yoy_growth_pct DESC, item_number
LIMIT 5;
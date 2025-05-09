WITH per_transaction AS (
  -- per‑liter retail price for every transaction from 2019‑2021
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS sales_year,
    state_bottle_retail / (bottle_volume_ml / 1000.0) AS price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) BETWEEN 2019 AND 2021
    AND bottle_volume_ml > 0
    AND category_name IS NOT NULL
),
avg_cat_year AS (
  -- average per‑liter price per category & year
  SELECT
    category_name,
    sales_year,
    AVG(price_per_liter) AS avg_price_per_liter
  FROM per_transaction
  GROUP BY category_name, sales_year
),
top10_2021 AS (
  -- top‑10 categories by 2021 average price
  SELECT
    category_name
  FROM avg_cat_year
  WHERE sales_year = 2021
  ORDER BY avg_price_per_liter DESC
  LIMIT 10
)
SELECT
  c.category_name AS category,
  ROUND(MAX(IF(sales_year = 2019, avg_price_per_liter, NULL)), 4) AS avg_price_2019,
  ROUND(MAX(IF(sales_year = 2020, avg_price_per_liter, NULL)), 4) AS avg_price_2020,
  ROUND(MAX(IF(sales_year = 2021, avg_price_per_liter, NULL)), 4) AS avg_price_2021
FROM avg_cat_year AS c
JOIN top10_2021 USING (category_name)
GROUP BY category
ORDER BY avg_price_2021 DESC
LIMIT 10;
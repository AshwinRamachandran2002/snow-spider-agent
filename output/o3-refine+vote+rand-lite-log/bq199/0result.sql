-- Average per‑liter retail prices for the top‑10 categories of 2021,
-- plus their averages for 2019 and 2020
WITH per_year AS (   -- step 1: average price per liter by category & year
  SELECT
    category,
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    AVG( SAFE_DIVIDE(sale_dollars , NULLIF(volume_sold_liters,0)) ) AS avg_price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) IN (2019,2020,2021)
    AND volume_sold_liters IS NOT NULL
    AND volume_sold_liters <> 0
  GROUP BY category, category_name, yr
),
top_2021 AS (        -- step 2: pick the 10 most expensive categories in 2021
  SELECT category
  FROM per_year
  WHERE yr = 2021
  ORDER BY avg_price_per_liter DESC
  LIMIT 10
)
SELECT                -- step 3: show the three‑year averages for those categories
  p.category,
  MAX(p.category_name)                       AS category_name,
  ROUND( MAX( CASE WHEN yr = 2019 THEN avg_price_per_liter END ), 4) AS avg_price_per_liter_2019,
  ROUND( MAX( CASE WHEN yr = 2020 THEN avg_price_per_liter END ), 4) AS avg_price_per_liter_2020,
  ROUND( MAX( CASE WHEN yr = 2021 THEN avg_price_per_liter END ), 4) AS avg_price_per_liter_2021
FROM per_year p
JOIN top_2021 t
  ON p.category = t.category
GROUP BY p.category
ORDER BY avg_price_per_liter_2021 DESC, p.category;
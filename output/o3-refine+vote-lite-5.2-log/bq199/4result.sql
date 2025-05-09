WITH per_tx AS (
  -- 1.  Calculate a per‑transaction retail price per liter
  SELECT
    category,
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    -- price per bottle ÷ liters per bottle
    state_bottle_retail * 1000.0 / bottle_volume_ml AS price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) IN (2019, 2020, 2021)
        AND bottle_volume_ml > 0              -- guard against bad data
        AND state_bottle_retail IS NOT NULL
),
avg_price AS (
  -- 2.  Average that per‑liter price within each category & year
  SELECT
    category,
    category_name,
    yr,
    AVG(price_per_liter) AS avg_price_per_liter
  FROM per_tx
  GROUP BY category, category_name, yr
),
top_2021 AS (
  -- 3.  Pick the 10 most‑expensive categories in 2021
  SELECT
    category,
    category_name
  FROM avg_price
  WHERE yr = 2021
  ORDER BY avg_price_per_liter DESC
  LIMIT 10
)
-- 4.  Return 2019‑2021 averages for those categories
SELECT
  t.category_name,
  ROUND(MAX(CASE WHEN a.yr = 2019 THEN a.avg_price_per_liter END), 4) AS avg_price_2019,
  ROUND(MAX(CASE WHEN a.yr = 2020 THEN a.avg_price_per_liter END), 4) AS avg_price_2020,
  ROUND(MAX(CASE WHEN a.yr = 2021 THEN a.avg_price_per_liter END), 4) AS avg_price_2021
FROM top_2021 AS t
JOIN avg_price AS a
  USING (category, category_name)
GROUP BY t.category_name
ORDER BY avg_price_2021 DESC, t.category_name;
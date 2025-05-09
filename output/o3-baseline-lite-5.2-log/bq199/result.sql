-- Top 10 liquor categories in 2021 (by average per‑liter retail price)
-- and their average per‑liter retail prices for 2019‑2021
WITH per_transaction AS (
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    -- price per liter for this sales line
    state_bottle_retail / (bottle_volume_ml / 1000.0) AS price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
        bottles_sold > 0               -- ignore returns / corrections
    AND bottle_volume_ml > 0           -- safety check
    AND EXTRACT(YEAR FROM `date`) IN (2019, 2020, 2021)
),
avg_cat_year AS (
  SELECT
    category_name,
    yr,
    AVG(price_per_liter) AS avg_price_per_liter
  FROM per_transaction
  GROUP BY category_name, yr
),
top10_2021 AS (
  SELECT
    category_name
  FROM avg_cat_year
  WHERE yr = 2021
  ORDER BY avg_price_per_liter DESC
  LIMIT 10
)
SELECT
  a.category_name,
  ROUND(MAX(IF(yr = 2019, avg_price_per_liter, NULL)), 4) AS avg_per_liter_2019,
  ROUND(MAX(IF(yr = 2020, avg_price_per_liter, NULL)), 4) AS avg_per_liter_2020,
  ROUND(MAX(IF(yr = 2021, avg_price_per_liter, NULL)), 4) AS avg_per_liter_2021
FROM avg_cat_year a
JOIN top10_2021 USING (category_name)
GROUP BY
  a.category_name
ORDER BY
  avg_per_liter_2021 DESC,
  a.category_name;
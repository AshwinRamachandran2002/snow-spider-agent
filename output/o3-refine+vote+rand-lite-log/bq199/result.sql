WITH per_txn AS (
  -- Per‑transaction retail price per liter for 2019‑2021
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    state_bottle_retail * 1000.0 / bottle_volume_ml AS price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `date` BETWEEN '2019-01-01' AND '2021-12-31'
    AND bottle_volume_ml > 0
    AND state_bottle_retail IS NOT NULL
    AND bottles_sold > 0            -- exclude returns/negative sales
),
avg_prices AS (
  -- Average per‑liter price by category & year
  SELECT
    category_name,
    yr,
    AVG(price_per_liter) AS avg_price_per_liter
  FROM per_txn
  GROUP BY category_name, yr
),
top_2021 AS (
  -- Top 10 categories in 2021 by highest avg per‑liter price
  SELECT
    category_name
  FROM avg_prices
  WHERE yr = 2021
  ORDER BY avg_price_per_liter DESC
  LIMIT 10
)
SELECT
  t.category_name,
  ROUND(MAX(CASE WHEN yr = 2019 THEN avg_price_per_liter END), 4) AS avg_price_2019,
  ROUND(MAX(CASE WHEN yr = 2020 THEN avg_price_per_liter END), 4) AS avg_price_2020,
  ROUND(MAX(CASE WHEN yr = 2021 THEN avg_price_per_liter END), 4) AS avg_price_2021
FROM avg_prices p
JOIN top_2021 t
  ON p.category_name = t.category_name
GROUP BY t.category_name
ORDER BY avg_price_2021 DESC, t.category_name;
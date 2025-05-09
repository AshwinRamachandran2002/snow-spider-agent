WITH per_transaction AS (
  -- Calculate per‑liter retail price for every row in 2019‑2021
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    -- price per litre = retail price per bottle ÷ (millilitres / 1000)
    (state_bottle_retail * 1000.0) / bottle_volume_ml AS price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `date` BETWEEN '2019-01-01' AND '2021-12-31'
    AND bottle_volume_ml > 0                     -- guard against bad data
    AND state_bottle_retail IS NOT NULL
),

top10_2021 AS (
  -- Find the 10 costliest categories (by average price) in 2021
  SELECT
    category_name,
    AVG(price_per_liter) AS avg_price_2021
  FROM per_transaction
  WHERE yr = 2021
  GROUP BY category_name
  ORDER BY avg_price_2021 DESC
  LIMIT 10
)

SELECT
  t.category_name,
  ROUND(AVG(CASE WHEN p.yr = 2019 THEN p.price_per_liter END), 4) AS avg_price_2019,
  ROUND(AVG(CASE WHEN p.yr = 2020 THEN p.price_per_liter END), 4) AS avg_price_2020,
  ROUND(AVG(CASE WHEN p.yr = 2021 THEN p.price_per_liter END), 4) AS avg_price_2021
FROM top10_2021 t
JOIN per_transaction p
  ON p.category_name = t.category_name
GROUP BY t.category_name
ORDER BY avg_price_2021 DESC, t.category_name;
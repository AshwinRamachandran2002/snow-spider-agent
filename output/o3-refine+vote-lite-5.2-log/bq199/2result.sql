/* Top 10 liquor categories in 2021 by average per‑liter retail price,
   together with their 2019‑2021 averages. */
WITH yearly AS (
  SELECT
    category,                         -- keeps the category code unique
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    AVG(state_bottle_retail / (bottle_volume_ml / 1000.0)) AS avg_price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `date` BETWEEN '2019-01-01' AND '2021-12-31'
        AND bottle_volume_ml > 0                     -- defensive filter
  GROUP BY category, category_name, yr
),
top_2021 AS (
  SELECT category
  FROM yearly
  WHERE yr = 2021
  ORDER BY avg_price_per_liter DESC
  LIMIT 10
)
SELECT
  y.category_name,
  ROUND(MAX(CASE WHEN y.yr = 2019 THEN y.avg_price_per_liter END), 4) AS avg_per_liter_2019,
  ROUND(MAX(CASE WHEN y.yr = 2020 THEN y.avg_price_per_liter END), 4) AS avg_per_liter_2020,
  ROUND(MAX(CASE WHEN y.yr = 2021 THEN y.avg_price_per_liter END), 4) AS avg_per_liter_2021
FROM yearly AS y
JOIN top_2021 AS t
  ON y.category = t.category
GROUP BY y.category_name
ORDER BY avg_per_liter_2021 DESC;
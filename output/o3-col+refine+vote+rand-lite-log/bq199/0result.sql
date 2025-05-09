-- Top-10 liquor categories by 2021 average per-liter retail price
-- and their corresponding averages for 2019-2021
WITH filtered AS (
  SELECT
    category,
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    state_bottle_retail * 1000 / bottle_volume_ml AS per_liter_retail
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE bottle_volume_ml > 0               -- avoid divide-by-zero
    AND state_bottle_retail > 0            -- ignore returns/credits
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2019 AND 2021
),
top10_2021 AS (
  SELECT category
  FROM filtered
  WHERE yr = 2021
  GROUP BY category
  ORDER BY AVG(per_liter_retail) DESC
  LIMIT 10
)
SELECT
  f.category,
  f.category_name,
  ROUND(AVG(CASE WHEN yr = 2019 THEN per_liter_retail END), 2) AS avg_per_liter_2019,
  ROUND(AVG(CASE WHEN yr = 2020 THEN per_liter_retail END), 2) AS avg_per_liter_2020,
  ROUND(AVG(CASE WHEN yr = 2021 THEN per_liter_retail END), 2) AS avg_per_liter_2021
FROM filtered f
JOIN top10_2021 t
  ON f.category = t.category
GROUP BY f.category, f.category_name
ORDER BY avg_per_liter_2021 DESC;
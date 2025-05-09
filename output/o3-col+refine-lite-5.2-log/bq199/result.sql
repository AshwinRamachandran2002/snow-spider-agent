-- Top‑10 liquor categories by 2021 average per‑liter retail price
-- and their same‑metric averages for 2019‑2021
WITH per_year AS (
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    AVG(state_bottle_retail * 1000.0 / bottle_volume_ml) AS avg_retail_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE bottle_volume_ml > 0
    AND EXTRACT(YEAR FROM `date`) IN (2019, 2020, 2021)
  GROUP BY category_name, yr
),
top_2021 AS (
  SELECT category_name
  FROM per_year
  WHERE yr = 2021
  ORDER BY avg_retail_per_liter DESC
  LIMIT 10
)
SELECT
  p.category_name,
  p.yr AS year,
  ROUND(p.avg_retail_per_liter, 2) AS avg_retail_per_liter
FROM per_year AS p
JOIN top_2021 AS t USING (category_name)
ORDER BY p.category_name, p.yr;
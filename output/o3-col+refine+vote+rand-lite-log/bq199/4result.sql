/*  Top-10 categories in 2021 by average retail price per liter,
    then their 2019-2021 averages                                   */
WITH base AS (
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    -- per-liter retail price
    state_bottle_retail / (bottle_volume_ml / 1000.0) AS retail_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE bottles_sold      > 0      -- exclude returns/voids
    AND bottle_volume_ml  > 0
    AND state_bottle_retail > 0
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2019 AND 2021
),
top10_2021 AS (
  SELECT
    category_name
  FROM base
  WHERE yr = 2021
  GROUP BY category_name
  ORDER BY AVG(retail_per_liter) DESC
  LIMIT 10
)
SELECT
  b.category_name,
  b.yr AS year,
  ROUND(AVG(b.retail_per_liter), 4) AS avg_retail_per_liter
FROM base b
WHERE b.category_name IN (SELECT category_name FROM top10_2021)
GROUP BY b.category_name, b.yr
ORDER BY b.category_name, b.yr;
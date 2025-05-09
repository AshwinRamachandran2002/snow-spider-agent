-- Top-10 Iowa liquor categories of 2021 by average per-liter retail price
-- plus their 2019–2021 averages (BigQuery SQL)

WITH base AS (
  -- Row-level per-liter retail price for 2019-2021 positive sales
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`)                                         AS yr,
    state_bottle_retail / (bottle_volume_ml / 1000.0)                 AS retail_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE bottles_sold  > 0                 -- exclude returns / credit memos
    AND bottle_volume_ml > 0              -- safety check
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2019 AND 2021
),

top10_2021 AS (
  -- Identify the 10 priciest categories by 2021 average price
  SELECT category_name
  FROM base
  WHERE yr = 2021
  GROUP BY category_name
  ORDER BY AVG(retail_per_liter) DESC
  LIMIT 10
)

SELECT
  b.category_name,
  AVG(IF(b.yr = 2019, b.retail_per_liter, NULL)) AS avg_per_liter_2019,
  AVG(IF(b.yr = 2020, b.retail_per_liter, NULL)) AS avg_per_liter_2020,
  AVG(IF(b.yr = 2021, b.retail_per_liter, NULL)) AS avg_per_liter_2021
FROM base AS b
JOIN top10_2021 USING (category_name)
GROUP BY b.category_name
ORDER BY avg_per_liter_2021 DESC;
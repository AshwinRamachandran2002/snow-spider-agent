WITH per_txn AS (
  SELECT
    `category`,
    `category_name`,
    EXTRACT(YEAR FROM `date`) AS yr,
    SAFE_DIVIDE(`sale_dollars`, `volume_sold_liters`) AS price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `sale_dollars` > 0
    AND `volume_sold_liters` > 0
    AND EXTRACT(YEAR FROM `date`) IN (2019, 2020, 2021)
),
avg_price AS (
  SELECT
    `category`,
    `category_name`,
    yr,
    AVG(price_per_liter) AS avg_price_per_liter
  FROM per_txn
  GROUP BY `category`, `category_name`, yr
),
top10_2021 AS (
  SELECT `category`
  FROM avg_price
  WHERE yr = 2021
  ORDER BY avg_price_per_liter DESC
  LIMIT 10
)
SELECT
  a.`category`,
  ANY_VALUE(a.`category_name`) AS category_name,
  MAX(CASE WHEN a.yr = 2019 THEN ROUND(a.avg_price_per_liter,4) END) AS avg_price_2019,
  MAX(CASE WHEN a.yr = 2020 THEN ROUND(a.avg_price_per_liter,4) END) AS avg_price_2020,
  MAX(CASE WHEN a.yr = 2021 THEN ROUND(a.avg_price_per_liter,4) END) AS avg_price_2021
FROM avg_price a
JOIN top10_2021 t
  ON a.`category` = t.`category`
GROUP BY a.`category`
ORDER BY avg_price_2021 DESC;
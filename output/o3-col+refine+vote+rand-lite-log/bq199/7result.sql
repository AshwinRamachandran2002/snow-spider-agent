/* Top-10 liquor categories by 2021 average per-liter retail price
   and their average prices for 2019-2021                         */

WITH per_sale AS (          -- price per liter for each transaction
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS sales_year,
    state_bottle_retail / (bottle_volume_ml / 1000.0) AS price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE category_name IS NOT NULL
),

top10_2021 AS (             -- ten most-expensive categories in 2021
  SELECT
    category_name,
    AVG(price_per_liter) AS avg_price_2021
  FROM per_sale
  WHERE sales_year = 2021
  GROUP BY category_name
  ORDER BY avg_price_2021 DESC
  LIMIT 10
)

SELECT
  t.category_name,
  ROUND(AVG(CASE WHEN p.sales_year = 2019 THEN p.price_per_liter END), 4) AS avg_per_liter_2019,
  ROUND(AVG(CASE WHEN p.sales_year = 2020 THEN p.price_per_liter END), 4) AS avg_per_liter_2020,
  ROUND(AVG(CASE WHEN p.sales_year = 2021 THEN p.price_per_liter END), 4) AS avg_per_liter_2021
FROM top10_2021   AS t
JOIN per_sale     AS p
  ON p.category_name = t.category_name
WHERE p.sales_year IN (2019, 2020, 2021)
GROUP BY t.category_name
ORDER BY avg_per_liter_2021 DESC;
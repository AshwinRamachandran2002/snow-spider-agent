-- Average per‑liter retail prices for the top‑10 liquor categories (by 2021 average)
WITH per_liter AS (
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    -- price per litre = retail price per bottle ÷ (bottle_volume_ml / 1 000)
    (state_bottle_retail * 1000.0) / bottle_volume_ml AS pl_price
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `date` BETWEEN '2019-01-01' AND '2021-12-31'
        AND bottle_volume_ml > 0                     -- safety check
),
yearly_avg AS (
  SELECT
    category_name,
    yr,
    AVG(pl_price) AS avg_pl_price
  FROM per_liter
  GROUP BY category_name, yr
),
pivoted AS (
  SELECT
    category_name,
    ROUND(MAX(IF(yr = 2019, avg_pl_price, NULL)), 4) AS avg_price_2019,
    ROUND(MAX(IF(yr = 2020, avg_pl_price, NULL)), 4) AS avg_price_2020,
    ROUND(MAX(IF(yr = 2021, avg_pl_price, NULL)), 4) AS avg_price_2021
  FROM yearly_avg
  GROUP BY category_name
)
SELECT *
FROM pivoted
WHERE avg_price_2021 IS NOT NULL
ORDER BY avg_price_2021 DESC
LIMIT 10;
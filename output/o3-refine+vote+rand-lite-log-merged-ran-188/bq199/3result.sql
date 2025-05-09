WITH per_txn AS (
  -- 1.  Calculate per–transaction per‑liter retail price for 2019‑2021
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    (state_bottle_retail * 1000.0) / bottle_volume_ml AS per_liter_price
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `date` BETWEEN '2019-01-01' AND '2021-12-31'
        AND bottle_volume_ml > 0
        AND state_bottle_retail IS NOT NULL
        AND category_name IS NOT NULL
),
top_2021 AS (
  -- 2.  Pick the 10 categories with the highest average per‑liter price in 2021
  SELECT
    category_name
  FROM per_txn
  WHERE yr = 2021
  GROUP BY category_name
  ORDER BY AVG(per_liter_price) DESC
  LIMIT 10
)
-- 3.  Show the (unweighted) average per‑liter price for those categories in 2019‑2021
SELECT
  category_name,
  ROUND(AVG(CASE WHEN yr = 2019 THEN per_liter_price END), 4) AS avg_per_liter_2019,
  ROUND(AVG(CASE WHEN yr = 2020 THEN per_liter_price END), 4) AS avg_per_liter_2020,
  ROUND(AVG(CASE WHEN yr = 2021 THEN per_liter_price END), 4) AS avg_per_liter_2021
FROM per_txn
WHERE category_name IN (SELECT category_name FROM top_2021)
GROUP BY category_name
ORDER BY avg_per_liter_2021 DESC, category_name;
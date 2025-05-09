-- Top-10 2021 categories and their average per-liter retail prices
-- for 2019, 2020 and 2021
WITH per_txn AS (
  -- Compute per-transaction per-liter retail price
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS sale_year,
    state_bottle_retail * 1000 / bottle_volume_ml AS per_liter_retail
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE bottles_sold       > 0        -- ignore returns / invalid rows
    AND state_bottle_retail > 0
    AND bottle_volume_ml    > 0
    AND EXTRACT(YEAR FROM `date`) IN (2019, 2020, 2021)
),
top_categories_2021 AS (
  -- Identify the ten most-expensive categories (by avg per-liter price) in 2021
  SELECT category_name
  FROM per_txn
  WHERE sale_year = 2021
  GROUP BY category_name
  ORDER BY AVG(per_liter_retail) DESC
  LIMIT 10
)
SELECT
  category_name,
  AVG(IF(sale_year = 2019, per_liter_retail, NULL)) AS avg_2019_per_liter_retail,
  AVG(IF(sale_year = 2020, per_liter_retail, NULL)) AS avg_2020_per_liter_retail,
  AVG(IF(sale_year = 2021, per_liter_retail, NULL)) AS avg_2021_per_liter_retail
FROM per_txn
WHERE category_name IN (SELECT category_name FROM top_categories_2021)
GROUP BY category_name
ORDER BY avg_2021_per_liter_retail DESC;
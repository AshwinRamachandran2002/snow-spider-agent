-- Top-10 2021 categories and their avg per-liter retail prices in 2019-2021
WITH
/* 1. 2021 per-liter averages for every category */
cat_2021 AS (
  SELECT
    category,
    AVG(state_bottle_retail * 1000.0 / bottle_volume_ml) AS avg_pl_2021
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM date) = 2021
  GROUP BY category
  ORDER BY avg_pl_2021 DESC
  LIMIT 10            -- keep only the ten highest
),

/* 2. Per-liter averages for the years of interest, restricted to those top categories */
yr_avgs AS (
  SELECT
    s.category,
    ANY_VALUE(s.category_name) AS category_name,
    EXTRACT(YEAR FROM s.date)  AS sales_year,
    AVG(s.state_bottle_retail * 1000.0 / s.bottle_volume_ml) AS avg_pl
  FROM `bigquery-public-data.iowa_liquor_sales.sales` AS s
  JOIN cat_2021 AS t
    ON s.category = t.category
  WHERE EXTRACT(YEAR FROM s.date) IN (2019, 2020, 2021)
  GROUP BY s.category, sales_year
)

/* 3. Pivot the three years side-by-side */
SELECT
  category,
  category_name,
  MAX(CASE WHEN sales_year = 2019 THEN avg_pl END) AS avg_2019_per_liter,
  MAX(CASE WHEN sales_year = 2020 THEN avg_pl END) AS avg_2020_per_liter,
  MAX(CASE WHEN sales_year = 2021 THEN avg_pl END) AS avg_2021_per_liter
FROM yr_avgs
GROUP BY category, category_name
ORDER BY avg_2021_per_liter DESC;
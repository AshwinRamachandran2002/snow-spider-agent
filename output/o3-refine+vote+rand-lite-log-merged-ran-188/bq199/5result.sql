WITH yearly_category_price AS (
  /*  Per‑year average of the per‑liter retail price for every category  */
  SELECT
    EXTRACT(YEAR FROM `date`)                         AS yr,
    category_name,
    AVG( state_bottle_retail * 1000.0 / bottle_volume_ml ) AS avg_per_liter_price
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
        EXTRACT(YEAR FROM `date`) IN (2019, 2020, 2021)     -- years of interest
    AND bottles_sold > 0                                    -- ignore returns / corrections
    AND bottle_volume_ml > 0                                -- avoid div‑by‑zero
    AND category_name IS NOT NULL
  GROUP BY yr, category_name
),
top_2021 AS (
  /*  Top‑10 categories by 2021 average per‑liter retail price  */
  SELECT
    category_name
  FROM yearly_category_price
  WHERE yr = 2021
  ORDER BY avg_per_liter_price DESC
  LIMIT 10
)
SELECT
  t.category_name,
  ROUND( MAX(CASE WHEN y.yr = 2019 THEN y.avg_per_liter_price END), 4 ) AS avg_price_2019,
  ROUND( MAX(CASE WHEN y.yr = 2020 THEN y.avg_per_liter_price END), 4 ) AS avg_price_2020,
  ROUND( MAX(CASE WHEN y.yr = 2021 THEN y.avg_per_liter_price END), 4 ) AS avg_price_2021
FROM top_2021 t
JOIN yearly_category_price y
  ON t.category_name = y.category_name
GROUP BY t.category_name
ORDER BY avg_price_2021 DESC, t.category_name;
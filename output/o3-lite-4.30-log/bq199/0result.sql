WITH txns AS (
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS yr,
    SAFE_DIVIDE(sale_dollars, volume_sold_liters) AS price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) BETWEEN 2019 AND 2021
    AND volume_sold_liters <> 0
),
cat_year_avg AS (
  SELECT
    category_name,
    yr,
    AVG(price_per_liter) AS avg_price
  FROM txns
  GROUP BY category_name, yr
),
top_2021 AS (
  SELECT
    category_name
  FROM cat_year_avg
  WHERE yr = 2021
  ORDER BY avg_price DESC, category_name
  LIMIT 10
)
SELECT
  t.category_name                                 AS category,
  ROUND(MAX(CASE WHEN c.yr = 2019 THEN c.avg_price END), 4) AS avg_price_2019,
  ROUND(MAX(CASE WHEN c.yr = 2020 THEN c.avg_price END), 4) AS avg_price_2020,
  ROUND(MAX(CASE WHEN c.yr = 2021 THEN c.avg_price END), 4) AS avg_price_2021
FROM top_2021 t
JOIN cat_year_avg c
  ON t.category_name = c.category_name
GROUP BY category
ORDER BY avg_price_2021 DESC, category;
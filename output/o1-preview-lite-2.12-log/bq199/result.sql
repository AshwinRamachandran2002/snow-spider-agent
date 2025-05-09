WITH avg_prices AS (
  SELECT
    category_name,
    EXTRACT(YEAR FROM `date`) AS year,
    SUM(sale_dollars) / SUM(volume_sold_liters) AS avg_price_per_liter
  FROM
    `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
    category_name IS NOT NULL
    AND sale_dollars > 0
    AND volume_sold_liters > 0
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2019 AND 2021
  GROUP BY
    category_name,
    year
),
top_categories AS (
  SELECT
    category_name
  FROM
    avg_prices
  WHERE
    year = 2021
  ORDER BY
    avg_price_per_liter DESC
  LIMIT
    10
)
SELECT
  avg_prices.category_name,
  avg_prices.year,
  ROUND(avg_prices.avg_price_per_liter, 4) AS avg_price_per_liter
FROM
  avg_prices
JOIN
  top_categories USING (category_name)
ORDER BY
  avg_prices.category_name,
  avg_prices.year;
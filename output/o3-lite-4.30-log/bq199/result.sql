WITH sales_2019_2021 AS (
  SELECT
    category,
    EXTRACT(YEAR FROM `date`) AS sales_year,
    sale_dollars / volume_sold_liters AS price_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE sale_dollars > 0
    AND volume_sold_liters > 0
    AND EXTRACT(YEAR FROM `date`) IN (2019, 2020, 2021)
),
avg_by_cat_year AS (
  SELECT
    category,
    sales_year,
    AVG(price_per_liter) AS avg_price_per_liter
  FROM sales_2019_2021
  GROUP BY category, sales_year
),
top10_2021 AS (
  SELECT category
  FROM avg_by_cat_year
  WHERE sales_year = 2021
  ORDER BY avg_price_per_liter DESC
  LIMIT 10
)
SELECT
  category,
  ROUND(MAX(IF(sales_year = 2019, avg_price_per_liter, NULL)), 4) AS avg_price_2019,
  ROUND(MAX(IF(sales_year = 2020, avg_price_per_liter, NULL)), 4) AS avg_price_2020,
  ROUND(MAX(IF(sales_year = 2021, avg_price_per_liter, NULL)), 4) AS avg_price_2021
FROM avg_by_cat_year
WHERE category IN (SELECT category FROM top10_2021)
GROUP BY category
ORDER BY avg_price_2021 DESC, category;
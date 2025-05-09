WITH ranked_zip AS (
  SELECT
    CAST(SPLIT(zip_code, '.')[OFFSET(0)] AS STRING) AS zip5,
    SUM(sale_dollars) AS total_bourbon_sales_2022,
    RANK() OVER (ORDER BY SUM(sale_dollars) DESC) AS rnk
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND EXTRACT(YEAR FROM date) = 2022
    AND LOWER(category_name) LIKE '%bourbon%'
  GROUP BY zip5
),
target_zip AS (
  SELECT zip5
  FROM ranked_zip
  WHERE rnk = 3
),
adult_population AS (
  SELECT
    zipcode AS zip5,
    SUM(population) AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE zipcode IN (SELECT zip5 FROM target_zip)
    AND minimum_age >= 21
  GROUP BY zipcode
),
monthly_sales AS (
  SELECT
    EXTRACT(MONTH FROM date) AS month,
    SUM(sale_dollars) AS bourbon_sales_usd
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND CAST(SPLIT(zip_code, '.')[OFFSET(0)] AS STRING) IN (SELECT zip5 FROM target_zip)
    AND EXTRACT(YEAR FROM date) = 2022
    AND LOWER(category_name) LIKE '%bourbon%'
  GROUP BY month
)
SELECT
  ms.month,
  ROUND(SAFE_DIVIDE(ms.bourbon_sales_usd, ap.pop_21_plus), 4) AS per_capita_bourbon_whiskey_sales_usd
FROM monthly_sales AS ms
JOIN adult_population AS ap
ON TRUE
ORDER BY ms.month;
-- Monthly 2022 per-capita Bourbon-whiskey sales (USD)  
-- for the ZIP code that ranks third in total 2022 Bourbon sales
-- in Dubuque County, using only the 21-and-older population.

WITH bourbon_totals AS (               -- total 2022 Bourbon sales by 5-digit ZIP
  SELECT
    SUBSTR(zip_code, 1, 5) AS zip5,
    SUM(sale_dollars)      AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND EXTRACT(YEAR FROM date) = 2022
    AND LOWER(category_name) LIKE '%bourbon%'
  GROUP BY zip5
),
third_zip AS (                         -- ZIP whose total sales rank third
  SELECT zip5
  FROM (
    SELECT
      zip5,
      total_sales,
      DENSE_RANK() OVER (ORDER BY total_sales DESC) AS rnk
    FROM bourbon_totals
  )
  WHERE rnk = 3
  LIMIT 1                               -- pick one if there is a tie
),
adult_population AS (                  -- 21-and-older population (2010 Census)
  SELECT
    SUM(population) AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE zipcode IN (SELECT zip5 FROM third_zip)
    AND (gender IS NULL OR gender = '') -- overall-population rows only
    AND minimum_age >= 21               -- age segments whose lower bound ≥ 21
),
monthly_sales AS (                     -- monthly 2022 Bourbon sales dollars
  SELECT
    FORMAT_DATE('%Y-%m', date) AS sales_month,
    SUM(sale_dollars)         AS monthly_sales_usd
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND SUBSTR(zip_code, 1, 5) IN (SELECT zip5 FROM third_zip)
    AND EXTRACT(YEAR FROM date) = 2022
    AND LOWER(category_name) LIKE '%bourbon%'
  GROUP BY sales_month
)
SELECT
  m.sales_month,
  ROUND(m.monthly_sales_usd / p.pop_21_plus, 4) AS per_capita_sales_usd
FROM monthly_sales   AS m
CROSS JOIN adult_population AS p
ORDER BY m.sales_month;
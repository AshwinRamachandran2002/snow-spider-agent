-- Monthly per-capita Bourbon-whiskey sales in 2022  
-- for the ZIP code that ranks 3rd in total Bourbon sales in Dubuque County
WITH bourbon_2022 AS (
  SELECT
    REGEXP_EXTRACT(`zip_code`, r'(\d{5})') AS zip5,
    `sale_dollars`,
    `date`
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `county` = 'DUBUQUE'
    AND `date` BETWEEN '2022-01-01' AND '2022-12-31'
    AND LOWER(`category_name`) LIKE '%bourbon%'
),
ranked_zips AS (
  SELECT
    zip5,
    SUM(sale_dollars) AS total_sales_2022,
    DENSE_RANK() OVER (ORDER BY SUM(sale_dollars) DESC) AS rk
  FROM bourbon_2022
  GROUP BY zip5
),
target_zip AS (
  SELECT zip5
  FROM ranked_zips
  WHERE rk = 3
),
monthly_sales AS (
  SELECT
    FORMAT_DATE('%Y-%m', date) AS year_month,
    SUM(sale_dollars)          AS monthly_sales_dollars
  FROM bourbon_2022
  WHERE zip5 = (SELECT zip5 FROM target_zip)
  GROUP BY year_month
),
pop_21_plus AS (
  SELECT
    SUM(population) AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE zipcode = (SELECT zip5 FROM target_zip)
    AND minimum_age IS NOT NULL
    AND minimum_age >= 21
)
SELECT
  m.year_month,
  m.monthly_sales_dollars,
  m.monthly_sales_dollars / p.pop_21_plus AS per_capita_sales_dollars
FROM monthly_sales AS m
CROSS JOIN pop_21_plus AS p
ORDER BY m.year_month;
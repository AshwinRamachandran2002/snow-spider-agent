-- Monthly per–capita Bourbon-whiskey sales (2022) for Dubuque County ZIP that ranks 3rd in total Bourbon sales
WITH bourbon_2022 AS (
  SELECT
    REGEXP_EXTRACT(CAST(zip_code AS STRING), r'^(\d{5})') AS zip5,
    sale_dollars
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND EXTRACT(YEAR FROM date) = 2022
    AND LOWER(category_name) LIKE '%bourbon%'
),
ranked_zip AS (
  SELECT
    zip5,
    SUM(sale_dollars) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(sale_dollars) DESC) AS sales_rank
  FROM bourbon_2022
  GROUP BY zip5
),
target_zip AS (          -- the ZIP code that ranks 3rd
  SELECT zip5
  FROM ranked_zip
  WHERE sales_rank = 3
),
pop21 AS (               -- 2010 population aged 21+
  SELECT
    zipcode,
    SUM(population) AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE zipcode IN (SELECT zip5 FROM target_zip)
    AND minimum_age >= 21
  GROUP BY zipcode
),
monthly_sales AS (
  SELECT
    FORMAT_DATE('%Y-%m', date) AS month,
    SUM(sale_dollars)           AS monthly_sales_dollars
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND EXTRACT(YEAR FROM date) = 2022
    AND LOWER(category_name) LIKE '%bourbon%'
    AND REGEXP_EXTRACT(CAST(zip_code AS STRING), r'^(\d{5})') IN (SELECT zip5 FROM target_zip)
  GROUP BY month
)
SELECT
  m.month,
  m.monthly_sales_dollars,
  p.pop_21_plus,
  m.monthly_sales_dollars / p.pop_21_plus AS sales_per_capita_dollars
FROM monthly_sales AS m
CROSS JOIN pop21 AS p
ORDER BY m.month;
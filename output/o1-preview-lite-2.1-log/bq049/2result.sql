WITH sales_data AS (
  SELECT
    EXTRACT(MONTH FROM date) AS month,
    SUM(sale_dollars) AS total_sales,
    REGEXP_REPLACE(CAST(zip_code AS STRING), r'\.0+$', '') AS zip_code_std
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND date BETWEEN '2022-01-01' AND '2022-12-31'
    AND (LOWER(category_name) LIKE '%bourbon%' OR LOWER(item_description) LIKE '%bourbon%')
  GROUP BY month, zip_code_std
),
monthly_sales AS (
  SELECT month, total_sales
  FROM sales_data
  WHERE zip_code_std = '52003'
),
population AS (
  SELECT SUM(population) AS population_over_21
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE zipcode = '52003'
    AND minimum_age >= 21
)

SELECT
  FORMAT_DATE('%b-2022', DATE(2022, month, 1)) AS Month,
  ROUND(total_sales / population.population_over_21, 4) AS Per_Capita_Sales
FROM monthly_sales
CROSS JOIN population
ORDER BY month;
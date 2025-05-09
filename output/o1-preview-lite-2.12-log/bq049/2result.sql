WITH bourbon_sales_by_zip AS (
  SELECT
    SUBSTR(CAST(zip_code AS STRING), 1, 5) AS zip_code,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
    EXTRACT(YEAR FROM date) = 2022
    AND LOWER(county) = 'dubuque'
    AND LOWER(category_name) LIKE '%bourbon%'
  GROUP BY zip_code
),
ranked_zip_codes AS (
  SELECT
    zip_code,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
  FROM bourbon_sales_by_zip
),
third_zip_code AS (
  SELECT zip_code
  FROM ranked_zip_codes
  WHERE sales_rank = 3
),
population_21plus AS (
  SELECT
    SUM(population) AS population_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE
    zipcode = (SELECT zip_code FROM third_zip_code)
    AND minimum_age IS NOT NULL
    AND CAST(minimum_age AS INT64) >= 21
    AND population IS NOT NULL
),
monthly_sales AS (
  SELECT
    EXTRACT(MONTH FROM date) AS month,
    SUM(sale_dollars) AS monthly_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
    EXTRACT(YEAR FROM date) = 2022
    AND LOWER(county) = 'dubuque'
    AND SUBSTR(CAST(zip_code AS STRING), 1, 5) = (SELECT zip_code FROM third_zip_code)
    AND LOWER(category_name) LIKE '%bourbon%'
  GROUP BY month
)
SELECT
  FORMAT_DATE('%b-%Y', DATE(2022, ms.month, 1)) AS Month,
  ROUND(ms.monthly_sales / p.population_21_plus, 4) AS Per_Capita_Sales
FROM monthly_sales AS ms
CROSS JOIN population_21plus AS p
ORDER BY ms.month;
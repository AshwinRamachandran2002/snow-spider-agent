WITH zip_sales AS (
  SELECT
    FORMAT('%05d', CAST(CAST(zip_code AS FLOAT64) AS INT64)) AS zip_code_formatted,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE UPPER(county) = 'DUBUQUE'
    AND EXTRACT(YEAR FROM date) = 2022
  GROUP BY zip_code_formatted
  ORDER BY total_sales DESC
),
third_zip AS (
  SELECT zip_code_formatted AS zip_code
  FROM zip_sales
  LIMIT 1 OFFSET 2
),
population_total AS (
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE
    zipcode = (SELECT zip_code FROM third_zip)
  GROUP BY zipcode
),
months AS (
  SELECT
    month_number,
    FORMAT_DATE('%b-%Y', DATE('2022-01-01') + INTERVAL month_number - 1 MONTH) AS Month
  FROM UNNEST(GENERATE_ARRAY(1,12)) AS month_number
),
monthly_sales AS (
  SELECT
    EXTRACT(MONTH FROM date) AS month_number,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
    UPPER(county) = 'DUBUQUE'
    AND FORMAT('%05d', CAST(CAST(zip_code AS FLOAT64) AS INT64)) = (SELECT zip_code FROM third_zip)
    AND LOWER(category_name) LIKE '%bourbon%'
    AND EXTRACT(YEAR FROM date) = 2022
  GROUP BY month_number
)
SELECT
  m.Month,
  ROUND(IFNULL(s.total_sales / p.total_population, 4), 4) AS Per_Capita_Sales
FROM months m
LEFT JOIN monthly_sales s ON m.month_number = s.month_number
CROSS JOIN population_total p
ORDER BY m.month_number;
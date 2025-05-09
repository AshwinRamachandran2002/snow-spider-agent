WITH
  total_sales_by_zip AS (
    SELECT
      REGEXP_REPLACE(CAST(zip_code AS STRING), r'\.0+$', '') AS zip_code,
      SUM(sale_dollars) AS total_sales
    FROM
      `bigquery-public-data.iowa_liquor_sales.sales`
    WHERE
      county = 'DUBUQUE'
      AND EXTRACT(YEAR FROM date) = 2022
      AND LOWER(category_name) LIKE '%bourbon%'
    GROUP BY
      zip_code
  ),
  ranked_sales AS (
    SELECT
      zip_code,
      total_sales,
      ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM
      total_sales_by_zip
  ),
  target_zip AS (
    SELECT
      zip_code
    FROM
      ranked_sales
    WHERE
      rank = 3
  ),
  population_over_21 AS (
    SELECT
      zipcode,
      SUM(population) AS population_over_21
    FROM
      `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
    WHERE
      (minimum_age >= 21 OR minimum_age IS NULL)
      AND gender IS NULL
    GROUP BY
      zipcode
  ),
  sales_data AS (
    SELECT
      s.date,
      s.sale_dollars,
      REGEXP_REPLACE(CAST(s.zip_code AS STRING), r'\.0+$', '') AS zip_code
    FROM
      `bigquery-public-data.iowa_liquor_sales.sales` AS s
    WHERE
      s.county = 'DUBUQUE'
      AND EXTRACT(YEAR FROM s.date) = 2022
      AND LOWER(s.category_name) LIKE '%bourbon%'
  )
SELECT
  FORMAT_DATE('%b-%Y', DATE_TRUNC(s.date, MONTH)) AS Month,
  ROUND(SUM(s.sale_dollars) / pop.population_over_21, 4) AS Per_Capita_Sales
FROM
  sales_data AS s
  JOIN target_zip AS tz ON s.zip_code = tz.zip_code
  JOIN population_over_21 AS pop ON s.zip_code = pop.zipcode
GROUP BY
  Month,
  pop.population_over_21
ORDER BY
  MIN(s.date);
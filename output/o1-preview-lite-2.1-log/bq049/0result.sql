WITH sales_total_per_zip AS (
  SELECT
    REGEXP_REPLACE(CAST(zip_code AS STRING), r'\.0+$', '') AS zip_code_norm,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE UPPER(county) = 'DUBUQUE' AND EXTRACT(YEAR FROM date) = 2022
  GROUP BY zip_code_norm
),
zip_code_ranked AS (
  SELECT
    zip_code_norm,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
  FROM sales_total_per_zip
),
target_zip AS (
  SELECT zip_code_norm
  FROM zip_code_ranked
  WHERE rn = 3
),
population_21_plus AS (
  SELECT
    REGEXP_REPLACE(zipcode, r'\.0+$', '') AS zip_code_norm,
    SUM(population) AS population_21_plus
  FROM
    `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE
    (SAFE_CAST(minimum_age AS INT64) >= 21 OR (SAFE_CAST(maximum_age AS INT64) >= 21))
    AND zipcode IS NOT NULL
  GROUP BY zip_code_norm
)
SELECT
  FORMAT_DATE('%b-%Y', sales.date) AS Month,
  SUM(sales.sale_dollars) / ANY_VALUE(population_21_plus.population_21_plus) AS Per_Capita_Sales
FROM `bigquery-public-data.iowa_liquor_sales.sales` AS sales
JOIN target_zip ON REGEXP_REPLACE(CAST(sales.zip_code AS STRING), r'\.0+$', '') = target_zip.zip_code_norm
JOIN population_21_plus ON population_21_plus.zip_code_norm = target_zip.zip_code_norm
WHERE
  UPPER(sales.county) = 'DUBUQUE' AND
  EXTRACT(YEAR FROM sales.date) = 2022 AND
  sales.category_name = 'STRAIGHT BOURBON WHISKIES'
GROUP BY Month
ORDER BY PARSE_DATE('%b-%Y', Month);
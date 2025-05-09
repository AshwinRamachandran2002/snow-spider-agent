WITH standardized_sales AS (
  SELECT
    REGEXP_REPLACE(CAST(s.zip_code AS STRING), r'\.\d*$', '') AS zip_code,
    s.date,
    s.county,
    s.category_name,
    s.item_description,
    s.sale_dollars
  FROM
    `bigquery-public-data.iowa_liquor_sales.sales` AS s
),
sales_per_zip AS (
  SELECT
    s.zip_code,
    SUM(s.sale_dollars) AS total_sales
  FROM
    standardized_sales AS s
  WHERE
    UPPER(TRIM(s.county)) = 'DUBUQUE'
    AND EXTRACT(YEAR FROM s.date) = 2022
    AND (LOWER(s.category_name) LIKE '%bourbon%' OR LOWER(s.item_description) LIKE '%bourbon%')
  GROUP BY
    s.zip_code
  ORDER BY
    total_sales DESC
),
third_zip_code AS (
  SELECT
    zip_code
  FROM
    sales_per_zip
  LIMIT 1 OFFSET 2
),
population AS (
  SELECT
    p.zipcode,
    SUM(p.population) AS population_21_plus
  FROM
    `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  WHERE
    p.minimum_age >= 21
  GROUP BY
    p.zipcode
),
monthly_sales AS (
  SELECT
    s.zip_code,
    EXTRACT(MONTH FROM s.date) AS month,
    SUM(s.sale_dollars) AS total_sales
  FROM
    standardized_sales AS s
  JOIN
    third_zip_code AS z
    ON s.zip_code = z.zip_code
  WHERE
    EXTRACT(YEAR FROM s.date) = 2022
    AND (LOWER(s.category_name) LIKE '%bourbon%' OR LOWER(s.item_description) LIKE '%bourbon%')
  GROUP BY
    s.zip_code,
    month
),
final_population AS (
  SELECT
    p.zipcode,
    p.population_21_plus
  FROM
    population AS p
  JOIN
    third_zip_code AS z
    ON p.zipcode = z.zip_code
)
SELECT
  FORMAT_DATE('%b-%Y', DATE(2022, m.month, 1)) AS Month,
  ROUND(m.total_sales / p.population_21_plus, 4) AS Per_Capita_Sales
FROM
  monthly_sales AS m
JOIN
  final_population AS p
  ON m.zip_code = p.zipcode
ORDER BY
  m.month;
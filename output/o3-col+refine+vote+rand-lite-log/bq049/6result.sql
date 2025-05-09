WITH third_zip AS (        -- ZIP code that ranks 3rd in 2022 Dubuque-county Bourbon sales
  SELECT
    SUBSTR(zip_code, 1, 5) AS zip5
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND EXTRACT(YEAR FROM date) = 2022
    AND LOWER(category_name) LIKE '%bourbon%'
  GROUP BY zip5
  ORDER BY SUM(sale_dollars) DESC
  LIMIT 1 OFFSET 2          -- 0-based offset → 3rd place
),
pop21 AS (                  -- 21-and-older population for that ZIP
  SELECT
    zipcode AS zip5,
    SUM(population) AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  JOIN third_zip ON zipcode = third_zip.zip5
  WHERE minimum_age >= 21           -- adults only
  GROUP BY zipcode
),
monthly_sales AS (           -- Monthly 2022 Bourbon sales for that ZIP
  SELECT
    FORMAT_DATE('%Y-%m', date) AS year_month,
    SUM(sale_dollars)         AS monthly_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  JOIN third_zip
    ON SUBSTR(zip_code, 1, 5) = third_zip.zip5
  WHERE county = 'DUBUQUE'
    AND EXTRACT(YEAR FROM date) = 2022
    AND LOWER(category_name) LIKE '%bourbon%'
  GROUP BY year_month
)
SELECT
  ms.year_month,
  ms.monthly_sales,
  p.pop_21_plus,
  ROUND(ms.monthly_sales / p.pop_21_plus, 4) AS per_capita_sales
FROM monthly_sales AS ms
JOIN pop21         AS p ON TRUE
ORDER BY ms.year_month;
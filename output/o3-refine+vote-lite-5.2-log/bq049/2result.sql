-- Monthly per–capita Bourbon‐whiskey sales (2022) in Dubuque County  
-- for the ZIP code that ranks 3rd in total Bourbon sales
WITH bourbon_sales_2022 AS (          -- all 2022 Bourbon sales in Dubuque County
  SELECT
    LPAD(REGEXP_EXTRACT(zip_code, r'(\d{5})'), 5, '0') AS zip5,
    sale_dollars
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND EXTRACT(YEAR FROM date) = 2022
    AND UPPER(category_name) LIKE '%BOURBON%'
    AND sale_dollars > 0                          -- ignore returns / negative values
),
zip_rank AS (                         -- rank ZIP codes by total Bourbon sales
  SELECT
    zip5,
    SUM(sale_dollars) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(sale_dollars) DESC, zip5) AS rnk
  FROM bourbon_sales_2022
  GROUP BY zip5
),
third_zip AS (                        -- the ZIP code in 3rd place
  SELECT zip5
  FROM zip_rank
  WHERE rnk = 3
),
population_21 AS (                    -- 21‑and‑over population for that ZIP
  SELECT
    zipcode AS zip5,
    SUM(population) AS pop21
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age >= 21
    AND zipcode IN (SELECT zip5 FROM third_zip)
  GROUP BY zipcode
),
monthly_sales AS (                    -- monthly Bourbon sales for that ZIP
  SELECT
    FORMAT_DATE('%Y-%m', date) AS month,
    SUM(sale_dollars) AS total_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND EXTRACT(YEAR FROM date) = 2022
    AND UPPER(category_name) LIKE '%BOURBON%'
    AND sale_dollars > 0
    AND LPAD(REGEXP_EXTRACT(zip_code, r'(\d{5})'), 5, '0') IN (SELECT zip5 FROM third_zip)
  GROUP BY month
)
SELECT
  month,
  ROUND(total_sales / pop21, 4) AS per_capita_sales
FROM monthly_sales
CROSS JOIN population_21
ORDER BY month;
/* Monthly per‑capita Bourbon‑whiskey sales (dollars) in 2022
   for the Dubuque‑County ZIP code that ranks 3rd in total 2022 Bourbon sales,
   using the 21‑and‑older population from the 2010 census */
WITH adult_population AS (
  SELECT
    LPAD(zipcode, 5, '0') AS zipcode,
    -- total population: rows where both age bounds and gender are NULL
    MAX(CASE WHEN gender IS NULL AND minimum_age IS NULL THEN population END) AS total_pop,
    -- population whose entire age‑range is < 21
    SUM(CASE WHEN gender IS NULL AND maximum_age < 21 THEN population END)    AS under21_pop
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  GROUP BY zipcode
),
adult_21_plus AS (
  SELECT
    zipcode,
    (total_pop - IFNULL(under21_pop, 0)) AS pop_21_plus
  FROM adult_population
  WHERE total_pop IS NOT NULL
),
bourbon_sales_2022 AS (
  -- Total 2022 Bourbon sales by ZIP (Dubuque County only)
  SELECT
    LPAD(REGEXP_EXTRACT(zip_code, r'^(\d{5})'), 5, '0') AS zipcode,
    SUM(sale_dollars)                                   AS total_sales_2022
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) = 2022
    AND UPPER(county) = 'DUBUQUE'
    AND LOWER(category_name) LIKE '%bourbon%'
  GROUP BY zipcode
),
third_place_zip AS (
  -- ZIP code ranking 3rd in 2022 Bourbon sales
  SELECT zipcode
  FROM bourbon_sales_2022
  ORDER BY total_sales_2022 DESC
  LIMIT 1 OFFSET 2         -- 0‑based offset ⇒ 3rd place
),
monthly_zip_sales AS (
  -- Monthly Bourbon sales for that ZIP in 2022
  SELECT
    FORMAT_DATE('%Y-%m', s.`date`) AS month,
    SUM(s.sale_dollars)            AS monthly_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales` AS s
  CROSS JOIN third_place_zip z
  WHERE EXTRACT(YEAR FROM s.`date`) = 2022
    AND UPPER(s.county) = 'DUBUQUE'
    AND LOWER(s.category_name) LIKE '%bourbon%'
    AND LPAD(REGEXP_EXTRACT(s.zip_code, r'^(\d{5})'), 5, '0') = z.zipcode
  GROUP BY month
)
SELECT
  m.month,
  m.monthly_sales / p.pop_21_plus AS per_capita_bourbon_sales
FROM monthly_zip_sales AS m
CROSS JOIN third_place_zip z
JOIN adult_21_plus  AS p
  ON p.zipcode = z.zipcode
ORDER BY m.month;
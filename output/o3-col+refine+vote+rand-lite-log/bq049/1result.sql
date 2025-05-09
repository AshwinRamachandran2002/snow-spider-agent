WITH ranked_zip AS (
  -- 1️⃣  Rank Dubuque-County ZIP codes by total 2022 Bourbon-category sales
  SELECT
    REGEXP_EXTRACT(CAST(`zip_code` AS STRING), r'^\d{5}') AS zip5,
    SUM(`sale_dollars`)                     AS total_sales,
    DENSE_RANK() OVER (ORDER BY SUM(`sale_dollars`) DESC) AS rk
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `county` = 'DUBUQUE'
    AND EXTRACT(YEAR FROM `date`) = 2022
    AND LOWER(`category_name`) LIKE '%bourbon%'
  GROUP BY zip5
),
target_zip AS (
  -- 2️⃣  Keep only the ZIP code that ranks third
  SELECT zip5
  FROM ranked_zip
  WHERE rk = 3
),
pop21 AS (
  -- 3️⃣  21-and-older population for that ZIP (2010 Census)
  SELECT
    SUM(`population`) AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE `zipcode` IN (SELECT zip5 FROM target_zip)
    AND `minimum_age` >= 21
)
-- 4️⃣  Monthly per-capita Bourbon sales for the 3rd-ranking ZIP
SELECT
  DATE_TRUNC(s.`date`, MONTH)                              AS month,
  SUM(s.`sale_dollars`) / pop21.pop_21_plus                AS per_capita_sales
FROM `bigquery-public-data.iowa_liquor_sales.sales` AS s
JOIN target_zip tz
  ON REGEXP_EXTRACT(CAST(s.`zip_code` AS STRING), r'^\d{5}') = tz.zip5
CROSS JOIN pop21
WHERE s.`county` = 'DUBUQUE'
  AND EXTRACT(YEAR FROM s.`date`) = 2022
  AND LOWER(s.`category_name`) LIKE '%bourbon%'
GROUP BY month, pop21.pop_21_plus
ORDER BY month;
-- Monthly per‑capita Bourbon‑whiskey sales in 2022  
-- for the Dubuque‑county ZIP code that ranks 3rd in total Bourbon sales  
WITH ranked_zip AS (         -- 1. rank Dubuque ZIP codes by total 2022 bourbon sales
  SELECT
    LPAD(REGEXP_EXTRACT(`zip_code`, r'^\d+'), 5, '0') AS zip5,
    SUM(`sale_dollars`)                               AS total_sales,
    RANK() OVER (ORDER BY SUM(`sale_dollars`) DESC)   AS sales_rank
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `county` = 'DUBUQUE'
    AND EXTRACT(YEAR FROM `date`) = 2022
    AND LOWER(`category_name`) LIKE '%bourbon%'
  GROUP BY zip5
),
pop_21_plus AS (            -- 2. 21‑and‑older population for every ZIP
  SELECT
    LPAD(REGEXP_EXTRACT(`zipcode`, r'^\d+'), 5, '0') AS zip5,
    SUM(`population`)                               AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE `minimum_age` >= 21          -- only age‑21‑plus rows
  GROUP BY zip5
),
target_zip AS (             -- 3. the 3rd‑ranked ZIP with its 21+ population
  SELECT r.zip5, p.pop_21_plus
  FROM   ranked_zip   AS r
  JOIN   pop_21_plus  AS p
  ON     r.zip5 = p.zip5
  WHERE  r.sales_rank = 3
)
-- 4. monthly sales and per‑capita figures for that ZIP
SELECT
  EXTRACT(MONTH FROM s.`date`)                     AS month,
  SUM(s.`sale_dollars`)                           AS monthly_sales,
  SUM(s.`sale_dollars`) / t.pop_21_plus           AS per_capita_sales
FROM   `bigquery-public-data.iowa_liquor_sales.sales` AS s
JOIN   target_zip AS t
ON     LPAD(REGEXP_EXTRACT(s.`zip_code`, r'^\d+'), 5, '0') = t.zip5
WHERE  s.`county` = 'DUBUQUE'
  AND  EXTRACT(YEAR FROM s.`date`) = 2022
  AND  LOWER(s.`category_name`) LIKE '%bourbon%'
GROUP BY month, t.pop_21_plus
ORDER BY month;
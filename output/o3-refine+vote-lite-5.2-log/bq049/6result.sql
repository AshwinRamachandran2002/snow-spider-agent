-- Monthly per–capita Bourbon‑whiskey sales (age‑21+ pop) in 2022  
-- for the Dubuque‑county ZIP code that ranks 3rd in total 2022
WITH population_21_plus AS (               -- age‑21+ population by ZIP
  SELECT
    LPAD(zipcode, 5, '0')                AS zip5,
    SUM(population)                      AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE gender IS NULL
    AND minimum_age IS NOT NULL
    AND minimum_age >= 21
  GROUP BY zip5
),
bourbon_sales AS (                         -- 2022 Bourbon sales by ZIP & month
  SELECT
    REGEXP_EXTRACT(zip_code, r'\d{5}')    AS zip5,
    DATE_TRUNC(date, MONTH)               AS month,
    SUM(sale_dollars)                     AS sales_dollars
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM date) = 2022
    AND TRIM(UPPER(county)) = 'DUBUQUE'
    AND REGEXP_CONTAINS(UPPER(category_name), r'BOURBON')   -- Bourbon only
  GROUP BY zip5, month
  HAVING zip5 IS NOT NULL
),
zip_ranks AS (                             -- rank ZIPs by total Bourbon sales
  SELECT
    zip5,
    SUM(sales_dollars)                        AS total_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(sales_dollars) DESC)     AS rn,
    COUNT(*)     OVER ()                                         AS n_zips
  FROM bourbon_sales
  GROUP BY zip5
),
chosen_zip AS (                            -- 3rd‑place ZIP (or last if <3)
  SELECT zip5
  FROM zip_ranks
  WHERE (n_zips >= 3 AND rn = 3) OR (n_zips < 3 AND rn = n_zips)
),
months_2022 AS (                           -- generate all 12 months of 2022
  SELECT d AS month
  FROM UNNEST(GENERATE_DATE_ARRAY('2022-01-01',
                                  '2022-12-01',
                                  INTERVAL 1 MONTH)) AS d
)
SELECT
  FORMAT_DATE('%Y-%m', m.month)                                    AS month,
  SAFE_DIVIDE(COALESCE(s.sales_dollars, 0), p.pop_21_plus)         AS per_capita_bourbon_sales
FROM chosen_zip            AS z
CROSS JOIN months_2022     AS m
LEFT  JOIN bourbon_sales   AS s  ON s.zip5 = z.zip5 AND s.month = m.month
LEFT  JOIN population_21_plus AS p ON p.zip5 = z.zip5
ORDER BY month;
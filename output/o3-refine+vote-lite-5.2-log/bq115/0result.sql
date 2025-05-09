WITH under25 AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    SUM(midyear_population) AS under25_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE
    year = 2017
    AND total_flag = 'A'                 -- individual 5‑year age groups
    AND starting_age <= 24               -- 0‑4, 5‑9, 10‑14, 15‑19, 20‑24
  GROUP BY country_code
),
total AS (
  SELECT
    country_code,
    midyear_population AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE
    year = 2017
    AND total_flag = '*'                -- total, all ages
    AND starting_age = 0
    AND age_group_indicator = '+'       -- open‑ended (the grand total row)
)
SELECT
  t.country_code,
  u.country_name,
  ROUND(u.under25_pop / t.total_pop * 100, 4) AS percent_under25
FROM total t
JOIN under25 u
  USING (country_code)
ORDER BY percent_under25 DESC
LIMIT 1;
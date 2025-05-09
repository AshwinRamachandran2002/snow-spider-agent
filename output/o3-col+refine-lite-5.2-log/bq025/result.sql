-- Top‑10 countries in 2020 by share of population under age 20
WITH country_pop AS (
  SELECT
    country_code,
    country_name,
    -- total mid‑year population (single “*” row per country)
    SUM(CASE WHEN total_flag = '*' THEN midyear_population END) AS total_population,
    -- population in the four 5‑year groups that cover ages 0‑19
    SUM(CASE
          WHEN age_group_indicator = '-' AND starting_age IN (0, 5, 10, 15)
          THEN midyear_population
        END)                                                   AS under20_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2020
  GROUP BY country_code, country_name
)
SELECT
  country_name,
  under20_population,
  total_population,
  ROUND(100 * SAFE_DIVIDE(under20_population, total_population), 4) AS under20_pct
FROM country_pop
WHERE total_population > 0
ORDER BY under20_pct DESC, country_name
LIMIT 10;
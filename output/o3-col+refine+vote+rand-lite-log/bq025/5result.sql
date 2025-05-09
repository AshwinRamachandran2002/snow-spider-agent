-- Top 10 countries in 2020 with the highest share of population under 20
WITH under20 AS (
  SELECT
    country_code,
    country_name,
    SUM(
         population_age_0  + population_age_1  + population_age_2  + population_age_3  + population_age_4 +
         population_age_5  + population_age_6  + population_age_7  + population_age_8  + population_age_9 +
         population_age_10 + population_age_11 + population_age_12 + population_age_13 + population_age_14 +
         population_age_15 + population_age_16 + population_age_17 + population_age_18 + population_age_19
       ) AS population_under_20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_age_sex`
  WHERE year = 2020
  GROUP BY country_code, country_name
),
totals AS (
  SELECT
    country_code,
    midyear_population AS total_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
)
SELECT
  u.country_code,
  u.country_name,
  u.population_under_20,
  t.total_population,
  ROUND(100.0 * u.population_under_20 / t.total_population, 4) AS pct_under_20
FROM under20 AS u
JOIN totals  AS t
  ON u.country_code = t.country_code
ORDER BY pct_under_20 DESC
LIMIT 10;
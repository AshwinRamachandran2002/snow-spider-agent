-- Top 10 countries in 2020 ranked by the share of population that is younger than 20
WITH under20 AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    SUM(
      population_age_0  + population_age_1  + population_age_2  + population_age_3  + population_age_4 +
      population_age_5  + population_age_6  + population_age_7  + population_age_8  + population_age_9 +
      population_age_10 + population_age_11 + population_age_12 + population_age_13 + population_age_14 +
      population_age_15 + population_age_16 + population_age_17 + population_age_18 + population_age_19
    ) AS population_under20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_age_sex`
  WHERE year = 2020
  GROUP BY country_code
),

total_pop AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
)

SELECT
  t.country_name,
  t.country_code,
  u.population_under20,
  t.total_population,
  ROUND(u.population_under20 * 100.0 / t.total_population, 4) AS percent_under20
FROM under20 u
JOIN total_pop t
  USING (country_code)
WHERE t.total_population > 0
ORDER BY percent_under20 DESC, t.country_name
LIMIT 10;
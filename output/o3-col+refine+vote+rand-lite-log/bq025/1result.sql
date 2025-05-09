-- Top 10 countries in 2020 with the largest share of population under 20 years old
WITH under20 AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    -- sum ages 0-19 for both sexes
    SUM(
      population_age_0 + population_age_1 + population_age_2 + population_age_3 +
      population_age_4 + population_age_5 + population_age_6 + population_age_7 +
      population_age_8 + population_age_9 + population_age_10 + population_age_11 +
      population_age_12 + population_age_13 + population_age_14 + population_age_15 +
      population_age_16 + population_age_17 + population_age_18 + population_age_19
    ) AS pop_under20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_age_sex`
  WHERE year = 2020
  GROUP BY country_code
),
total AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
)

SELECT
  u.country_name,
  u.pop_under20,
  t.total_pop,
  ROUND(100 * u.pop_under20 / t.total_pop, 2) AS pct_under20
FROM under20 AS u
JOIN total  AS t
USING (country_code)
WHERE t.total_pop > 0
ORDER BY pct_under20 DESC
LIMIT 10;
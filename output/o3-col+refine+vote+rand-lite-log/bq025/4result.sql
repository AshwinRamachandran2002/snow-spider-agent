-- Top 10 countries in 2020 with the highest share of population under 20
WITH under_20 AS (
  SELECT
    country_code,
    country_name,
    -- sum ages 0-19 for every sex, then aggregate across sexes
    SUM(
      COALESCE(population_age_0 ,0)+COALESCE(population_age_1 ,0)+COALESCE(population_age_2 ,0)+COALESCE(population_age_3 ,0)+
      COALESCE(population_age_4 ,0)+COALESCE(population_age_5 ,0)+COALESCE(population_age_6 ,0)+COALESCE(population_age_7 ,0)+
      COALESCE(population_age_8 ,0)+COALESCE(population_age_9 ,0)+COALESCE(population_age_10,0)+COALESCE(population_age_11,0)+
      COALESCE(population_age_12,0)+COALESCE(population_age_13,0)+COALESCE(population_age_14,0)+COALESCE(population_age_15,0)+
      COALESCE(population_age_16,0)+COALESCE(population_age_17,0)+COALESCE(population_age_18,0)+COALESCE(population_age_19,0)
    ) AS population_under_20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_age_sex`
  WHERE year = 2020
  GROUP BY country_code, country_name
)

SELECT
  u.country_code,
  u.country_name,
  u.population_under_20,
  t.midyear_population AS total_population,
  ROUND(SAFE_DIVIDE(u.population_under_20, t.midyear_population) * 100, 2) AS pct_under_20
FROM under_20 AS u
JOIN `bigquery-public-data.census_bureau_international.midyear_population` AS t
  ON t.year = 2020
  AND u.country_code = t.country_code
ORDER BY pct_under_20 DESC
LIMIT 10;
WITH population_under20 AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    -- sum ages 0 through 19 for every sex, then sum across the two sexes
    SUM( COALESCE(population_age_0 ,0)  + COALESCE(population_age_1 ,0)  + COALESCE(population_age_2 ,0)  +
         COALESCE(population_age_3 ,0)  + COALESCE(population_age_4 ,0)  + COALESCE(population_age_5 ,0)  +
         COALESCE(population_age_6 ,0)  + COALESCE(population_age_7 ,0)  + COALESCE(population_age_8 ,0)  +
         COALESCE(population_age_9 ,0)  + COALESCE(population_age_10,0)  + COALESCE(population_age_11,0)  +
         COALESCE(population_age_12,0)  + COALESCE(population_age_13,0)  + COALESCE(population_age_14,0)  +
         COALESCE(population_age_15,0)  + COALESCE(population_age_16,0)  + COALESCE(population_age_17,0)  +
         COALESCE(population_age_18,0)  + COALESCE(population_age_19,0)
       ) AS pop_under20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_age_sex`
  WHERE year = 2020
  GROUP BY country_code
)

SELECT
  u.country_name,
  u.country_code,
  u.pop_under20,
  t.midyear_population AS total_population,
  ROUND(100.0 * u.pop_under20 / t.midyear_population, 4) AS pct_under20
FROM population_under20 u
JOIN `bigquery-public-data.census_bureau_international.midyear_population` t
  ON u.country_code = t.country_code
 WHERE t.year = 2020
ORDER BY pct_under20 DESC, country_name
LIMIT 10;
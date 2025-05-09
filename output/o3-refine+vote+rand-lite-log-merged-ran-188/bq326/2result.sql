WITH pop AS (
  SELECT
    country_code,
    (year_2018 - year_2017) / CAST(year_2017 AS FLOAT64) AS pop_growth
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
),
chexp AS (
  SELECT
    country_code,
    (MAX(CASE WHEN year = 2018 THEN value END) -
     MAX(CASE WHEN year = 2017 THEN value END))
     / MAX(CASE WHEN year = 2017 THEN value END) AS chexp_growth
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'
    AND year IN (2017, 2018)
  GROUP BY country_code
  HAVING MAX(CASE WHEN year = 2017 THEN value END) IS NOT NULL
     AND MAX(CASE WHEN year = 2018 THEN value END) IS NOT NULL
)
SELECT COUNT(*) AS num_countries
FROM pop
JOIN chexp USING (country_code)
WHERE pop_growth  > 0.01
  AND chexp_growth > 0.01;
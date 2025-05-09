WITH pop_growth AS (
  SELECT
    country_code,
    (year_2018 - year_2017) / year_2017 AS pop_growth_rate
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
),
hexp_values AS (
  SELECT
    country_code,
    MAX(CASE WHEN year = 2017 THEN value END) AS val_2017,
    MAX(CASE WHEN year = 2018 THEN value END) AS val_2018
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'
    AND year IN (2017, 2018)
  GROUP BY country_code
),
hexp_growth AS (
  SELECT
    country_code,
    (val_2018 - val_2017) / val_2017 AS hexp_growth_rate
  FROM hexp_values
  WHERE val_2017 IS NOT NULL
    AND val_2018 IS NOT NULL
)
SELECT
  COUNT(*) AS countries_count
FROM pop_growth pg
JOIN hexp_growth hg
  ON pg.country_code = hg.country_code
WHERE pg.pop_growth_rate > 0.01
  AND hg.hexp_growth_rate > 0.01;
WITH country_list AS (
  SELECT country_code
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE region IS NOT NULL
    AND region <> 'Aggregates'
),
population_change AS (
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_pct_change
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND year_2017 <> 0
),
chexp_change AS (
  SELECT
    country_code,
    SAFE_DIVIDE(
      MAX(IF(year = 2018, value, NULL)) -
      MAX(IF(year = 2017, value, NULL)),
      MAX(IF(year = 2017, value, NULL))
    ) AS chexp_pct_change
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'
    AND year IN (2017, 2018)
  GROUP BY country_code
  HAVING
    MAX(IF(year = 2017, value, NULL)) IS NOT NULL
    AND MAX(IF(year = 2018, value, NULL)) IS NOT NULL
    AND MAX(IF(year = 2017, value, NULL)) <> 0
)
SELECT
  COUNT(*) AS countries_count
FROM country_list cl
JOIN population_change pc USING (country_code)
JOIN chexp_change cc USING (country_code)
WHERE pc.pop_pct_change > 0.01
  AND cc.chexp_pct_change > 0.01;
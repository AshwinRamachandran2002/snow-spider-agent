WITH pop_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_growth_pct
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
),
health_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(
      MAX(CASE WHEN year = 2018 THEN value END) -
      MAX(CASE WHEN year = 2017 THEN value END),
      MAX(CASE WHEN year = 2017 THEN value END)
    ) AS health_growth_pct
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'
    AND year IN (2017, 2018)
  GROUP BY country_code
  HAVING
    MAX(CASE WHEN year = 2017 THEN value END) IS NOT NULL
    AND MAX(CASE WHEN year = 2018 THEN value END) IS NOT NULL
)
SELECT
  COUNT(DISTINCT p.country_code) AS countries_with_growth_gt_1pct
FROM pop_growth p
JOIN health_growth h
  ON p.country_code = h.country_code
WHERE p.pop_growth_pct   > 0.01   -- > 1% population increase
  AND h.health_growth_pct > 0.01; -- > 1% per‑capita health expenditure increase
WITH pop_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_pct_change
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND year_2017 <> 0
),
health_values AS (
  SELECT
    country_code,
    MAX(CASE WHEN year = 2017 THEN value END) AS exp_2017,
    MAX(CASE WHEN year = 2018 THEN value END) AS exp_2018
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'        -- per‑capita current health expenditure, PPP
    AND year IN (2017, 2018)
  GROUP BY country_code
),
health_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(exp_2018 - exp_2017, exp_2017) AS exp_pct_change
  FROM health_values
  WHERE exp_2017 IS NOT NULL
    AND exp_2018 IS NOT NULL
    AND exp_2017 <> 0
),
valid_countries AS (
  -- keep only actual countries (World Bank assigns a region to real countries)
  SELECT DISTINCT country_code
  FROM `bigquery-public-data.world_bank_health_population.country_summary`
  WHERE region IS NOT NULL
)

SELECT COUNT(DISTINCT pg.country_code) AS country_count
FROM pop_growth  AS pg
JOIN health_growth AS hg USING (country_code)
JOIN valid_countries AS vc USING (country_code)
WHERE pg.pop_pct_change  > 0.01   -- >1% population growth
  AND hg.exp_pct_change  > 0.01;  -- >1% health‑expenditure growth
-- How many countries saw >1 % growth (2017 → 2018) in BOTH
--   1) total population and
--   2) per-capita current health expenditure (PPP)?

WITH pop_growth AS (
  SELECT
    country_code,
    (year_2018 - year_2017) / year_2017 AS pct_growth_pop
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND (year_2018 - year_2017) / year_2017 > 0.01          -- > 1 % population rise
),

chex_growth AS (
  SELECT
    country_code,
    (MAX(IF(year = 2018, value, NULL)) -
     MAX(IF(year = 2017, value, NULL))) /
     MAX(IF(year = 2017, value, NULL))   AS pct_growth_chex
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'                 -- per-capita CHE, PPP
    AND year IN (2017, 2018)
  GROUP BY country_code
  HAVING pct_growth_chex > 0.01                              -- > 1 % CHE rise
)

SELECT
  COUNT(*) AS countries_with_both_increases
FROM pop_growth
JOIN chex_growth USING (country_code);
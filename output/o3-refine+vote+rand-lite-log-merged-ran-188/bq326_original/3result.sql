-- Count of countries whose total population AND per‑capita current health expenditure (PPP)
-- both increased by more than 1 % from 2017 to 2018
WITH
-- 1. Population growth 2017‑2018
pop_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_pct_change
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND SAFE_DIVIDE(year_2018 - year_2017, year_2017) > 0.01   -- > 1 %
),

-- 2. Health‑expenditure per‑capita (PPP, current int’l $) growth 2017‑2018
health_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(val2018 - val2017, val2017) AS health_pct_change
  FROM (
    SELECT
      country_code,
      MAX(CASE WHEN year = 2017 THEN value END) AS val2017,
      MAX(CASE WHEN year = 2018 THEN value END) AS val2018
    FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
    WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'      -- Current health expenditure per capita, PPP
    GROUP BY country_code
  )
  WHERE val2017 IS NOT NULL
    AND val2018 IS NOT NULL
    AND SAFE_DIVIDE(val2018 - val2017, val2017) > 0.01          -- > 1 %
),

-- 3. Keep only actual countries (exclude aggregate rows)
real_countries AS (
  SELECT country_code
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE region IS NOT NULL
)

-- 4. Final count
SELECT
  COUNT(*) AS countries_with_over_1pct_growth_both_metrics
FROM pop_growth
JOIN health_growth USING (country_code)
JOIN real_countries USING (country_code);
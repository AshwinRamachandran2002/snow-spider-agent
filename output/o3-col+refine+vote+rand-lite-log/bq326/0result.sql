-- Countries whose population AND per-capita current health expenditure (PPP)
-- each grew by more than 1 % from 2017 to 2018
WITH pop_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_growth_ratio
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
),
hex_values AS (
  SELECT
    country_code,
    MAX(CASE WHEN year = 2017 THEN value END) AS hex_2017,
    MAX(CASE WHEN year = 2018 THEN value END) AS hex_2018
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'    -- per-capita current health expenditure, PPP
    AND year IN (2017, 2018)
  GROUP BY country_code
),
hex_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(hex_2018 - hex_2017, hex_2017) AS hex_growth_ratio
  FROM hex_values
  WHERE hex_2017 IS NOT NULL
    AND hex_2018 IS NOT NULL
)
SELECT COUNT(*) AS countries_with_both_increases
FROM pop_growth
JOIN hex_growth USING (country_code)
WHERE pop_growth_ratio  > 0.01   -- >1 % population growth
  AND hex_growth_ratio > 0.01;   -- >1 % health-expenditure growth
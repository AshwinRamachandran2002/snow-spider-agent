-- number of countries whose population and per-capita current health expenditure (PPP)
-- each grew by more than 1 % from 2017 to 2018
WITH pop_growth AS (
  SELECT
    country_code
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND (year_2018 - year_2017) / year_2017 > 0.01           -- > 1 % population growth
),
hexp_growth AS (
  SELECT
    country_code
  FROM (
    SELECT
      country_code,
      MAX(CASE WHEN year = 2017 THEN value END) AS val_2017,
      MAX(CASE WHEN year = 2018 THEN value END) AS val_2018
    FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
    WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'                -- per-capita current health-exp (PPP)
      AND year IN (2017, 2018)
    GROUP BY country_code
  )
  WHERE val_2017 IS NOT NULL
    AND val_2018 IS NOT NULL
    AND (val_2018 - val_2017) / val_2017 > 0.01               -- > 1 % expenditure growth
)
SELECT COUNT(*) AS countries_with_both_growth_over_1pct
FROM pop_growth
JOIN hexp_growth USING (country_code);
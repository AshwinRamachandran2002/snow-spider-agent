WITH pop_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_growth_rate
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
),
pop_ok AS (
  SELECT country_code
  FROM pop_growth
  WHERE pop_growth_rate > 0.01            -- > 1 % population growth
),

health_pivot AS (
  SELECT
    country_code,
    MAX(CASE WHEN year = 2017 THEN value END) AS h2017,
    MAX(CASE WHEN year = 2018 THEN value END) AS h2018
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'  -- Current health expenditure per capita, PPP
    AND year IN (2017, 2018)
  GROUP BY country_code
),
health_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(h2018 - h2017, h2017) AS health_growth_rate
  FROM health_pivot
  WHERE h2017 IS NOT NULL
    AND h2018 IS NOT NULL
),
health_ok AS (
  SELECT country_code
  FROM health_growth
  WHERE health_growth_rate > 0.01         -- > 1 % health‑spending growth
)

SELECT COUNT(*) AS countries_with_both_increases
FROM (
  SELECT country_code
  FROM pop_ok
  INNER JOIN health_ok USING (country_code)
)
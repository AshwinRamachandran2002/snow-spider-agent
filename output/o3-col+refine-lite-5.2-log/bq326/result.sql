WITH pop_growth AS (
  -- Countries whose total population grew by more than 1 % from 2017 to 2018
  SELECT country_code
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND SAFE_DIVIDE(year_2018 - year_2017, year_2017) > 0.01
),
hexp_growth AS (
  -- Countries whose per‑capita current health expenditure (PPP) grew by more than 1 % from 2017 to 2018
  SELECT country_code
  FROM (
    SELECT
      country_code,
      MAX(CASE WHEN year = 2017 THEN value END) AS he17,
      MAX(CASE WHEN year = 2018 THEN value END) AS he18
    FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
    WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'  -- Current health expenditure per capita, PPP
      AND year IN (2017, 2018)
    GROUP BY country_code
  )
  WHERE he17 IS NOT NULL
    AND he18 IS NOT NULL
    AND SAFE_DIVIDE(he18 - he17, he17) > 0.01
)
-- Count countries satisfying both conditions
SELECT COUNT(*) AS countries_with_both_growth
FROM pop_growth
JOIN hexp_growth USING (country_code);
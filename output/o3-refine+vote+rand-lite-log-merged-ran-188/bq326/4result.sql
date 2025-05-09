-- Countries with >1 % growth in BOTH population and per-capita current health
-- expenditure (PPP) from 2017 to 2018
WITH pop_growth AS (
  SELECT DISTINCT country_code
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND year_2018 > year_2017 * 1.01            -- >1 % population growth
),
health_exp_growth AS (
  SELECT country_code
  FROM (
    SELECT
      country_code,
      MAX(IF(year = 2017, value, NULL)) AS chexp_2017,
      MAX(IF(year = 2018, value, NULL)) AS chexp_2018
    FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
    WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'   -- per-capita current health exp. (PPP)
      AND year IN (2017, 2018)
    GROUP BY country_code
  )
  WHERE chexp_2017 IS NOT NULL
    AND chexp_2018 IS NOT NULL
    AND chexp_2018 > chexp_2017 * 1.01          -- >1 % expenditure growth
)
SELECT COUNT(*) AS countries_with_both_increases
FROM pop_growth
JOIN health_exp_growth USING (country_code);
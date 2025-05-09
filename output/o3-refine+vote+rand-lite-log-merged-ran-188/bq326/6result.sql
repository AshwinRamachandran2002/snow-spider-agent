-- Count countries whose population AND per-capita current health expenditure (PPP)
-- each grew by more than 1 % from 2017 to 2018
WITH pop AS (   -- population growth 2017→2018
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_growth
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
),
chexp AS (      -- per-capita health-expenditure growth 2017→2018
  SELECT
    country_code,
    (MAX(IF(year = 2018, value, NULL)) -
     MAX(IF(year = 2017, value, NULL)))
     / MAX(IF(year = 2017, value, NULL))          AS chexp_growth
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'      -- current health expenditure per capita, PPP
    AND year IN (2017, 2018)
  GROUP BY country_code
),
both AS (       -- keep countries exceeding 1 % on BOTH metrics
  SELECT p.country_code
  FROM pop   p
  JOIN chexp c USING (country_code)
  WHERE p.pop_growth  > 0.01
    AND c.chexp_growth > 0.01
    AND c.chexp_growth IS NOT NULL
)
SELECT COUNT(DISTINCT country_code) AS countries_with_growth_gt_1pct_both
FROM both;
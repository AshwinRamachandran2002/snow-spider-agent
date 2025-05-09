WITH pop_growth AS (
  -- Population % change 2017 → 2018
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_pct_change
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
),
health_growth AS (
  -- Per-capita current health-expenditure (PPP) % change 2017 → 2018
  SELECT
    country_code,
    SAFE_DIVIDE(
      MAX(IF(year = 2018, value, NULL)) -
      MAX(IF(year = 2017, value, NULL)),
      MAX(IF(year = 2017, value, NULL))
    ) AS health_pct_change
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'       -- per-capita current health expenditure, PPP
    AND year IN (2017, 2018)
  GROUP BY country_code
)
SELECT
  COUNT(*) AS num_countries_both_gt_1pct
FROM pop_growth
JOIN health_growth USING (country_code)
WHERE pop_pct_change   > 0.01      -- > 1 % population growth
  AND health_pct_change > 0.01;    -- > 1 % health-expenditure growth
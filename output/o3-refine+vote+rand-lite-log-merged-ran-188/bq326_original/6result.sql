-- Countries whose 2018 population AND per‑capita current health expenditure (PPP) 
-- each grew by more than 1 % over their 2017 levels
WITH pop_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_growth_rate
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND year_2017 > 0
),
health_vals AS (
  SELECT
    country_code,
    MAX(CASE WHEN year = 2017 THEN value END) AS val_2017,
    MAX(CASE WHEN year = 2018 THEN value END) AS val_2018
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'  -- per‑capita current health expenditure, PPP
    AND year IN (2017, 2018)
  GROUP BY country_code
),
health_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(val_2018 - val_2017, val_2017) AS health_growth_rate
  FROM health_vals
  WHERE val_2017 IS NOT NULL
    AND val_2018 IS NOT NULL
    AND val_2017 > 0
)
SELECT COUNT(*) AS countries_with_over_1pct_growth_in_both_metrics
FROM pop_growth p
JOIN health_growth h USING (country_code)
WHERE p.pop_growth_rate  > 0.01
  AND h.health_growth_rate > 0.01;
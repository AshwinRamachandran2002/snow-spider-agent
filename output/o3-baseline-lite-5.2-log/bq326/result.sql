-- Number of countries whose total population AND per‑capita current
-- health expenditure (PPP, current international $) grew by >1% from 2017 to 2018
WITH pop_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS growth_rate
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND year_2017 > 0
),
pop_ok AS (               -- population grew >1 %
  SELECT country_code
  FROM pop_growth
  WHERE growth_rate > 0.01
),

health_vals AS (          -- per‑capita current health expenditure, PPP
  SELECT
    country_code,
    MAX(IF(year = 2017, value, NULL)) AS val_2017,
    MAX(IF(year = 2018, value, NULL)) AS val_2018
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'          -- per‑capita CHE, PPP
  GROUP BY country_code
),
health_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(val_2018 - val_2017, val_2017) AS growth_rate
  FROM health_vals
  WHERE val_2017 IS NOT NULL
    AND val_2018 IS NOT NULL
    AND val_2017 > 0
),
health_ok AS (            -- health spending grew >1 %
  SELECT country_code
  FROM health_growth
  WHERE growth_rate > 0.01
)

SELECT COUNT(*) AS countries_with_both_increases
FROM (
  SELECT country_code FROM pop_ok
  INTERSECT DISTINCT
  SELECT country_code FROM health_ok
);
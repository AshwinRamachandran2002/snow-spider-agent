WITH pop_growth AS (
  SELECT
    country_code,
    (year_2018 - year_2017) / CAST(year_2017 AS FLOAT64) AS growth_pct
  FROM
    `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE
    year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND year_2017 > 0
),
pop_increase AS (
  SELECT country_code
  FROM pop_growth
  WHERE growth_pct > 0.01              -- > 1 % population increase
),
health_values AS (
  SELECT
    country_code,
    MAX(CASE WHEN year = 2017 THEN value END) AS val_2017,
    MAX(CASE WHEN year = 2018 THEN value END) AS val_2018
  FROM
    `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE
    indicator_code = 'SH.XPD.CHEX.PP.CD'   -- Current health expenditure per capita, PPP (current int$)
    AND year IN (2017, 2018)
  GROUP BY
    country_code
),
health_growth AS (
  SELECT
    country_code,
    (val_2018 - val_2017) / val_2017 AS growth_pct
  FROM
    health_values
  WHERE
    val_2017 IS NOT NULL
    AND val_2018 IS NOT NULL
    AND val_2017 > 0
),
health_increase AS (
  SELECT country_code
  FROM health_growth
  WHERE growth_pct > 0.01              -- > 1 % health‑expenditure increase
)
SELECT
  COUNT(*) AS countries_with_both_increase
FROM (
  SELECT country_code FROM pop_increase
  INTERSECT DISTINCT
  SELECT country_code FROM health_increase
);
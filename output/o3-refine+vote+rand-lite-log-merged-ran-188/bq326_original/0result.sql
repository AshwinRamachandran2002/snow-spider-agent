-- Number of countries whose population and per‑capita current health expenditure (PPP)
-- each rose by more than 1 % between 2017 and 2018
WITH pop_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(year_2018 - year_2017, year_2017) AS pop_growth_pct
  FROM
    `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE
    year_2018 IS NOT NULL
    AND year_2017 IS NOT NULL
    AND year_2017 > 0
),
health_growth AS (
  SELECT
    country_code,
    SAFE_DIVIDE(
      MAX(CASE WHEN year = 2018 THEN value END) -
      MAX(CASE WHEN year = 2017 THEN value END),
      MAX(CASE WHEN year = 2017 THEN value END)
    ) AS health_growth_pct
  FROM
    `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE
    indicator_code = 'SH.XPD.CHEX.PP.CD'
    AND year IN (2017, 2018)
  GROUP BY
    country_code
),
valid_countries AS (
  SELECT country_code
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE region IS NOT NULL          -- exclude aggregates/regions
)

SELECT COUNT(*) AS countries_with_both_increases
FROM valid_countries vc
JOIN pop_growth   p USING (country_code)
JOIN health_growth h USING (country_code)
WHERE
  p.pop_growth_pct   > 0.01   -- > 1 % population growth
  AND h.health_growth_pct > 0.01;  -- > 1 % health‑expenditure growth
WITH valid_countries AS (
  SELECT country_code
  FROM `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE region IS NOT NULL          -- filters out aggregates (regions, income groups, etc.)
),

pop_growth AS (
  SELECT
    country_code
  FROM
    `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE
    year_2017 IS NOT NULL
    AND year_2018 IS NOT NULL
    AND SAFE_DIVIDE(year_2018 - year_2017, year_2017) > 0.01
    AND country_code IN (SELECT country_code FROM valid_countries)
),

chex_growth AS (
  SELECT
    country_code
  FROM (
    SELECT
      country_code,
      MAX(CASE WHEN year = 2017 THEN value END) AS val_2017,
      MAX(CASE WHEN year = 2018 THEN value END) AS val_2018
    FROM
      `bigquery-public-data.world_bank_health_population.health_nutrition_population`
    WHERE
      indicator_code = 'SH.XPD.CHEX.PP.CD'
      AND year IN (2017, 2018)
      AND country_code IN (SELECT country_code FROM valid_countries)
    GROUP BY
      country_code
  )
  WHERE
    val_2017 IS NOT NULL
    AND val_2018 IS NOT NULL
    AND SAFE_DIVIDE(val_2018 - val_2017, val_2017) > 0.01
)

SELECT
  COUNT(*) AS countries_count
FROM
  pop_growth
JOIN
  chex_growth
USING (country_code);
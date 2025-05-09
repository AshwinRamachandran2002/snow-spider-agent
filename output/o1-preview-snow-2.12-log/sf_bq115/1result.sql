WITH population_under_25 AS (
  SELECT
    "country_name",
    SUM("population") AS population_under_25
  FROM
    CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
  WHERE
    "year" = 2017 AND "age" < 25
  GROUP BY
    "country_name"
),
total_population AS (
  SELECT
    "country_name",
    "midyear_population"
  FROM
    CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION
  WHERE
    "year" = 2017
)
SELECT
  u."country_name",
  ROUND((u.population_under_25 * 100.0 / t."midyear_population"), 4) AS percentage_under_25
FROM
  population_under_25 u
JOIN
  total_population t
ON u."country_name" = t."country_name"
ORDER BY
  percentage_under_25 DESC NULLS LAST
LIMIT 1;
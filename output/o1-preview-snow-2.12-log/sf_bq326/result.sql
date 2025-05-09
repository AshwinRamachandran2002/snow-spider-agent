WITH population_growth AS (
  SELECT
    "country_code",
    (( "year_2018" - "year_2017" ) / "year_2017" ) * 100 AS "population_growth_percent"
  FROM
    "WORLD_BANK"."WORLD_BANK_GLOBAL_POPULATION"."POPULATION_BY_COUNTRY"
  WHERE
    "year_2017" IS NOT NULL
    AND "year_2018" IS NOT NULL
    AND "year_2017" <> 0
),
health_expenditure_2017 AS (
  SELECT
    "country_code",
    "value" AS "expenditure_2017"
  FROM
    "WORLD_BANK"."WORLD_BANK_HEALTH_POPULATION"."HEALTH_NUTRITION_POPULATION"
  WHERE
    "indicator_name" = 'Current health expenditure per capita, PPP (current international $)'
    AND "year" = 2017
    AND "value" IS NOT NULL
),
health_expenditure_2018 AS (
  SELECT
    "country_code",
    "value" AS "expenditure_2018"
  FROM
    "WORLD_BANK"."WORLD_BANK_HEALTH_POPULATION"."HEALTH_NUTRITION_POPULATION"
  WHERE
    "indicator_name" = 'Current health expenditure per capita, PPP (current international $)'
    AND "year" = 2018
    AND "value" IS NOT NULL
),
health_expenditure_growth AS (
  SELECT
    h2017."country_code",
    ( ( h2018."expenditure_2018" - h2017."expenditure_2017" ) / h2017."expenditure_2017" ) * 100 AS "expenditure_growth_percent"
  FROM
    health_expenditure_2017 h2017
  JOIN
    health_expenditure_2018 h2018 ON h2017."country_code" = h2018."country_code"
  WHERE
    h2017."expenditure_2017" <> 0
)
SELECT
  COUNT( DISTINCT pg."country_code" ) AS "Number_of_Countries"
FROM
  population_growth pg
JOIN
  health_expenditure_growth heg ON pg."country_code" = heg."country_code"
WHERE
  pg."population_growth_percent" > 1
  AND heg."expenditure_growth_percent" > 1;
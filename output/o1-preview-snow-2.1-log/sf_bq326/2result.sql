WITH population_growth AS (
  SELECT "country_code",
    ROUND((("year_2018" - "year_2017") / "year_2017") * 100, 4) AS "pop_growth_percent"
  FROM WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY
  WHERE "year_2017" IS NOT NULL
    AND "year_2018" IS NOT NULL
    AND "year_2017" != 0
),
expenditure_growth AS (
  SELECT hn2017."country_code",
    ROUND(((hn2018."value" - hn2017."value") / hn2017."value") * 100, 4) AS "exp_growth_percent"
  FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION hn2017
  JOIN WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION hn2018
    ON hn2017."country_code" = hn2018."country_code"
       AND hn2017."indicator_code" = hn2018."indicator_code"
  WHERE hn2017."indicator_code" = 'SH.XPD.CHEX.PP.CD'
    AND hn2017."year" = 2017
    AND hn2018."year" = 2018
    AND hn2017."value" IS NOT NULL
    AND hn2018."value" IS NOT NULL
    AND hn2017."value" != 0
)
SELECT COUNT(DISTINCT pg."country_code") AS "Number_of_countries"
FROM population_growth pg
JOIN expenditure_growth eg ON pg."country_code" = eg."country_code"
WHERE pg."pop_growth_percent" > 1
  AND eg."exp_growth_percent" > 1;
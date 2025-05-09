WITH pop_growth AS (
    SELECT
        "country_code",
        "year_2017" AS pop_2017,
        "year_2018" AS pop_2018
    FROM WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY
    WHERE "year_2017" IS NOT NULL
      AND "year_2018" IS NOT NULL
      AND "year_2017" > 0
      AND (("year_2018" - "year_2017") / "year_2017") > 0.01          -- > 1 % growth
),
health_growth AS (
    SELECT
        "country_code",
        MAX(CASE WHEN "year" = 2017 THEN "value" END) AS hexp_2017,
        MAX(CASE WHEN "year" = 2018 THEN "value" END) AS hexp_2018
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE "indicator_code" = 'SH.XPD.CHEX.PP.CD'                      -- per-capita health expenditure, PPP
      AND "year" IN (2017, 2018)
    GROUP BY "country_code"
    HAVING hexp_2017 IS NOT NULL
       AND hexp_2018 IS NOT NULL
       AND hexp_2017 > 0
       AND ((hexp_2018 - hexp_2017) / hexp_2017) > 0.01               -- > 1 % growth
)
SELECT COUNT(*) AS "countries_with_over_1pct_growth_both"
FROM pop_growth pg
JOIN health_growth hg
  ON pg."country_code" = hg."country_code";
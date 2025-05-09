WITH pop_growth AS (   -- Countries whose total population grew >1 % between 2017 and 2018
    SELECT
        "country_code",
        ("year_2018" - "year_2017") / "year_2017" AS pop_pct_change
    FROM WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY
    WHERE "year_2017" IS NOT NULL
      AND "year_2018" IS NOT NULL
      AND ("year_2018" - "year_2017") / "year_2017" > 0.01
), 
he_percap AS (         -- Per-capita current health expenditure (PPP) for 2017 & 2018
    SELECT
        "country_code",
        MAX(CASE WHEN "year" = 2017 THEN "value" END) AS he2017,
        MAX(CASE WHEN "year" = 2018 THEN "value" END) AS he2018
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE  LOWER("indicator_name") LIKE '%current health expenditure per capita%'
       AND LOWER("indicator_name") LIKE '%ppp%'
    GROUP BY "country_code"
), 
he_growth AS (         -- Countries whose health expenditure grew >1 % between 2017 and 2018
    SELECT
        "country_code"
    FROM he_percap
    WHERE he2017 IS NOT NULL
      AND he2018 IS NOT NULL
      AND he2017 <> 0
      AND (he2018 - he2017) / he2017 > 0.01
)
-- Count countries that satisfy BOTH conditions
SELECT COUNT(DISTINCT p."country_code") AS countries_with_above_1pct_growth
FROM pop_growth  p
JOIN he_growth   h
  ON p."country_code" = h."country_code";
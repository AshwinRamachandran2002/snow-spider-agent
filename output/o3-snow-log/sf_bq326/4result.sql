WITH pop_change AS (
    SELECT 
        "country_code",
        "year_2017"          AS pop_2017,
        "year_2018"          AS pop_2018,
        CASE 
            WHEN "year_2017" <> 0 
            THEN ("year_2018" - "year_2017") / "year_2017" 
        END                 AS pop_pct_change
    FROM WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY
    WHERE "year_2017" IS NOT NULL 
      AND "year_2018" IS NOT NULL
), pop_increase AS (
    SELECT "country_code"
    FROM pop_change
    WHERE pop_pct_change > 0.01          -- > 1% population growth
), health_vals AS (
    SELECT
        "country_code",
        MAX(CASE WHEN "year" = 2017 THEN "value" END) AS he_2017,
        MAX(CASE WHEN "year" = 2018 THEN "value" END) AS he_2018
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE "indicator_code" = 'SH.XPD.CHEX.PP.CD'      -- per-capita health expenditure, PPP
      AND "year" IN (2017, 2018)
    GROUP BY "country_code"
), health_increase AS (
    SELECT "country_code"
    FROM health_vals
    WHERE he_2017 IS NOT NULL 
      AND he_2018 IS NOT NULL
      AND (he_2018 - he_2017) / he_2017 > 0.01        -- > 1% spending growth
)
SELECT COUNT(DISTINCT p."country_code") AS countries_with_population_and_health_spending_growth_over_1pct
FROM pop_increase p
JOIN health_increase h
  ON p."country_code" = h."country_code";
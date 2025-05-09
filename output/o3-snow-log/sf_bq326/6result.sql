WITH pop_growth AS (
    SELECT
        "country_code",
        "year_2017"                                  AS pop_2017,
        "year_2018"                                  AS pop_2018,
        CASE
            WHEN "year_2017" IS NOT NULL
                 AND "year_2018" IS NOT NULL
                 AND "year_2017" <> 0
            THEN ("year_2018" - "year_2017") / "year_2017"
        END                                          AS pop_growth_rate
    FROM WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY
),
pop_increase AS (
    SELECT "country_code"
    FROM pop_growth
    WHERE pop_growth_rate > 0.01          -- > 1 % population growth
),
health_values AS (
    SELECT
        "country_code",
        MAX(CASE WHEN "year" = 2017 THEN "value" END) AS chexp_2017,
        MAX(CASE WHEN "year" = 2018 THEN "value" END) AS chexp_2018
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE "indicator_code" = 'SH.XPD.CHEX.PP.CD'      -- per-capita current health expenditure (PPP)
    GROUP BY "country_code"
),
health_growth AS (
    SELECT
        "country_code",
        CASE
            WHEN chexp_2017 IS NOT NULL
                 AND chexp_2018 IS NOT NULL
                 AND chexp_2017 <> 0
            THEN (chexp_2018 - chexp_2017) / chexp_2017
        END AS chexp_growth_rate
    FROM health_values
),
health_increase AS (
    SELECT "country_code"
    FROM health_growth
    WHERE chexp_growth_rate > 0.01        -- > 1 % health-expenditure growth
)
SELECT COUNT(DISTINCT p."country_code") AS countries_with_both_increases
FROM pop_increase p
JOIN health_increase h
  ON p."country_code" = h."country_code";
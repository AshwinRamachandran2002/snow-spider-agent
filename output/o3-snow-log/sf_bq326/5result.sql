WITH pop AS (
    SELECT
        "country_code",
        "year_2017"::FLOAT AS pop_2017,
        "year_2018"::FLOAT AS pop_2018
    FROM WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY
),
health AS (
    SELECT
        "country_code",
        MAX(CASE WHEN "year" = 2017 THEN "value" END) AS health_2017,
        MAX(CASE WHEN "year" = 2018 THEN "value" END) AS health_2018
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE "indicator_code" = 'SH.XPD.CHEX.PP.CD'           -- per-capita current health expenditure, PPP
    GROUP BY "country_code"
),
combined AS (
    SELECT
        p."country_code",
        pop_2017,
        pop_2018,
        h.health_2017,
        h.health_2018
    FROM pop p
    JOIN health h
      ON p."country_code" = h."country_code"
)
SELECT
    COUNT(*) AS countries_with_over_1pct_growth_in_both_population_and_health_expenditure
FROM combined
WHERE
      pop_2017 IS NOT NULL
  AND pop_2018 IS NOT NULL
  AND pop_2017 > 0
  AND health_2017 IS NOT NULL
  AND health_2018 IS NOT NULL
  AND health_2017 > 0
  AND (pop_2018   - pop_2017)   / pop_2017   > 0.01     -- >1 % population growth
  AND (health_2018 - health_2017) / health_2017 > 0.01; -- >1 % health-spending growth
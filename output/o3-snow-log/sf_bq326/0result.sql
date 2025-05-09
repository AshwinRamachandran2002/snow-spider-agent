WITH pop AS (   -- total population 2017 vs 2018
    SELECT
        "country_code" AS country_code,
        "year_2017"   AS pop_2017,
        "year_2018"   AS pop_2018
    FROM "WORLD_BANK"."WORLD_BANK_GLOBAL_POPULATION"."POPULATION_BY_COUNTRY"
),
pop_growth AS (   -- % change in population
    SELECT
        country_code,
        (pop_2018 - pop_2017) / NULLIF(pop_2017, 0) * 100 AS pop_pct
    FROM pop
    WHERE pop_2017 IS NOT NULL
      AND pop_2018 IS NOT NULL
      AND pop_2017 <> 0
),
health AS (   -- per-capita current health expenditure (PPP), 2017 vs 2018
    SELECT
        "country_code" AS country_code,
        MAX(CASE WHEN "year" = 2017 THEN "value" END) AS heal_2017,
        MAX(CASE WHEN "year" = 2018 THEN "value" END) AS heal_2018
    FROM "WORLD_BANK"."WORLD_BANK_HEALTH_POPULATION"."HEALTH_NUTRITION_POPULATION"
    WHERE "indicator_code" = 'SH.XPD.CHEX.PP.CD'
      AND "year" IN (2017, 2018)
    GROUP BY "country_code"
),
health_growth AS (   -- % change in health expenditure
    SELECT
        country_code,
        (heal_2018 - heal_2017) / NULLIF(heal_2017, 0) * 100 AS heal_pct
    FROM health
    WHERE heal_2017 IS NOT NULL
      AND heal_2018 IS NOT NULL
      AND heal_2017 <> 0
),
both_growth AS (   -- countries meeting both >1% conditions
    SELECT
        p.country_code
    FROM pop_growth  p
    JOIN health_growth h
      ON p.country_code = h.country_code
    WHERE p.pop_pct  > 1
      AND h.heal_pct > 1
)
SELECT COUNT(*) AS "countries_with_>1pct_growth_in_2018"
FROM both_growth;
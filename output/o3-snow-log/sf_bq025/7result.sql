-- Top 10 countries in 2020 by share of population under age 20
WITH "pop_under_20" AS (
    SELECT
        "country_code",
        "country_name",
        SUM(
              COALESCE("population_age_0", 0)  + COALESCE("population_age_1", 0)  + COALESCE("population_age_2", 0)
            + COALESCE("population_age_3", 0)  + COALESCE("population_age_4", 0)  + COALESCE("population_age_5", 0)
            + COALESCE("population_age_6", 0)  + COALESCE("population_age_7", 0)  + COALESCE("population_age_8", 0)
            + COALESCE("population_age_9", 0)  + COALESCE("population_age_10", 0) + COALESCE("population_age_11", 0)
            + COALESCE("population_age_12", 0) + COALESCE("population_age_13", 0) + COALESCE("population_age_14", 0)
            + COALESCE("population_age_15", 0) + COALESCE("population_age_16", 0) + COALESCE("population_age_17", 0)
            + COALESCE("population_age_18", 0) + COALESCE("population_age_19", 0)
        ) AS "population_under_20"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION_AGE_SEX"
    WHERE "year" = 2020
    GROUP BY "country_code", "country_name"
)

SELECT
    u."country_code",
    u."country_name",
    u."population_under_20",
    p."midyear_population",
    ROUND(100.0 * u."population_under_20" / p."midyear_population", 4) AS "pct_under_20"
FROM "pop_under_20" u
JOIN CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION" p
  ON u."country_code" = p."country_code"
 AND p."year" = 2020
ORDER BY "pct_under_20" DESC NULLS LAST
LIMIT 10;
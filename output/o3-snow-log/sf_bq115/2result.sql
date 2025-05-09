WITH under25 AS (
    SELECT
        "country_code",
        MAX("country_name") AS "country_name",
        SUM(
              COALESCE("population_age_0", 0)  + COALESCE("population_age_1", 0)  + COALESCE("population_age_2", 0)
            + COALESCE("population_age_3", 0)  + COALESCE("population_age_4", 0)  + COALESCE("population_age_5", 0)
            + COALESCE("population_age_6", 0)  + COALESCE("population_age_7", 0)  + COALESCE("population_age_8", 0)
            + COALESCE("population_age_9", 0)  + COALESCE("population_age_10", 0) + COALESCE("population_age_11", 0)
            + COALESCE("population_age_12", 0) + COALESCE("population_age_13", 0) + COALESCE("population_age_14", 0)
            + COALESCE("population_age_15", 0) + COALESCE("population_age_16", 0) + COALESCE("population_age_17", 0)
            + COALESCE("population_age_18", 0) + COALESCE("population_age_19", 0) + COALESCE("population_age_20", 0)
            + COALESCE("population_age_21", 0) + COALESCE("population_age_22", 0) + COALESCE("population_age_23", 0)
            + COALESCE("population_age_24", 0)
        ) AS "pop_under25"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION_AGE_SEX"
    WHERE "year" = 2017
    GROUP BY "country_code"
),
total_pop AS (
    SELECT
        "country_code",
        MAX("country_name")     AS "country_name",
        MAX("midyear_population") AS "midyear_population"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION"
    WHERE "year" = 2017
    GROUP BY "country_code"
)
SELECT
    t."country_name",
    (u."pop_under25" / t."midyear_population") * 100 AS "pct_population_under_25"
FROM total_pop t
JOIN under25 u
  ON t."country_code" = u."country_code"
ORDER BY "pct_population_under_25" DESC NULLS LAST
LIMIT 1;
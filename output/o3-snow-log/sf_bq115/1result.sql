WITH "UNDER25" AS (
    SELECT
        "country_code",
        MAX("country_name")                        AS "country_name",
        SUM("population")                          AS "pop_under25"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
    WHERE "year" = 2017
      AND "age" <= 24
    GROUP BY "country_code"
),
"TOTALPOP" AS (
    SELECT
        "country_code",
        MAX("country_name")                        AS "country_name",
        SUM("midyear_population")                  AS "midyear_population"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION
    WHERE "year" = 2017
    GROUP BY "country_code"
)
SELECT
    t."country_name",
    (u."pop_under25" / t."midyear_population") * 100 AS "percent_population_under25"
FROM "UNDER25" u
JOIN "TOTALPOP" t
  ON u."country_code" = t."country_code"
ORDER BY "percent_population_under25" DESC NULLS LAST
LIMIT 1;
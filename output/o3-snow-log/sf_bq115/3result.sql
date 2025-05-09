WITH "under25" AS (
    SELECT
        "country_code",
        MAX("country_name")               AS "country_name",
        SUM("population")                 AS "under25_population"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
    WHERE "year" = 2017
      AND "age" BETWEEN 0 AND 24
    GROUP BY "country_code"
),
"total_pop" AS (
    SELECT
        "country_code",
        "midyear_population"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION
    WHERE "year" = 2017
)
SELECT
    u."country_name",
    u."country_code",
    (u."under25_population" / t."midyear_population") * 100 AS "pct_population_under_25"
FROM "under25" u
JOIN "total_pop" t
  ON u."country_code" = t."country_code"
ORDER BY "pct_population_under_25" DESC NULLS LAST
LIMIT 1;
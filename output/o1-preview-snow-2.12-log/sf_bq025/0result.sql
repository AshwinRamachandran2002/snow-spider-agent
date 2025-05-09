SELECT
    t1."country_name",
    t1."total_population_under_20" AS "population_under_20",
    t2."midyear_population" AS "total_midyear_population",
    ROUND((t1."total_population_under_20" * 100.0) / t2."midyear_population", 4) AS "percentage_under_20"
FROM
    (
        SELECT "country_name", SUM("population") AS "total_population_under_20"
        FROM "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION_AGESPECIFIC"
        WHERE "year" = 2020 AND "age" < 20
        GROUP BY "country_name"
    ) t1
JOIN
    (
        SELECT "country_name", "midyear_population"
        FROM "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION"
        WHERE "year" = 2020
    ) t2
ON t1."country_name" = t2."country_name"
ORDER BY "percentage_under_20" DESC NULLS LAST
LIMIT 10;
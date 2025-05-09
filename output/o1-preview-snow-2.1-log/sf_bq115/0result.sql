SELECT
    p."country_name",
    ROUND((CAST(u25."population_under_25" AS FLOAT) / CAST(p."midyear_population" AS FLOAT)) * 100, 4) AS "percentage_under_25"
FROM
    (SELECT
        "country_code",
        "country_name",
        SUM("population") AS "population_under_25"
     FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
     WHERE "year" = 2017 AND "age" < 25
     GROUP BY "country_code", "country_name") u25
JOIN
    (SELECT
        "country_code",
        "country_name",
        "midyear_population"
     FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION
     WHERE "year" = 2017) p
ON u25."country_code" = p."country_code" AND u25."country_name" = p."country_name"
ORDER BY "percentage_under_25" DESC NULLS LAST
LIMIT 1;
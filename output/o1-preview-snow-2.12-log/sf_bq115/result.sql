SELECT 
    a."country_name", 
    ROUND((a."population_under_25" / b."midyear_population") * 100, 4) AS "percentage_under_25"
FROM
    (
        SELECT "country_code", "country_name", SUM("population") AS "population_under_25"
        FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
        WHERE "year" = 2017 AND "age" < 25
        GROUP BY "country_code", "country_name"
    ) a
JOIN
    (
        SELECT "country_code", "country_name", "midyear_population"
        FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION
        WHERE "year" = 2017
    ) b
ON a."country_code" = b."country_code"
ORDER BY "percentage_under_25" DESC NULLS LAST
LIMIT 1;
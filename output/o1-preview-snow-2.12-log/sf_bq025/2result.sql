SELECT
    pop_under_20."country_name",
    pop_under_20."population_under_20",
    total_pop."midyear_population" AS "total_midyear_population",
    ROUND((pop_under_20."population_under_20" / total_pop."midyear_population") * 100, 4) AS "percentage_under_20"
FROM
    (
        SELECT
            "country_name",
            SUM("population") AS "population_under_20"
        FROM
            "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION_AGESPECIFIC"
        WHERE
            "year" = 2020 AND "age" < 20
        GROUP BY
            "country_name"
    ) AS pop_under_20
JOIN
    (
        SELECT
            "country_name",
            "midyear_population"
        FROM
            "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION"
        WHERE
            "year" = 2020
    ) AS total_pop
ON
    pop_under_20."country_name" = total_pop."country_name"
ORDER BY
    "percentage_under_20" DESC NULLS LAST,
    pop_under_20."population_under_20" DESC
LIMIT 10;
SELECT
    a."country_name",
    b.population_under_20,
    a."midyear_population" AS total_midyear_population,
    ROUND((b.population_under_20 / a."midyear_population") * 100, 4) AS percentage_under_20
FROM
    CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION" a
JOIN
    (
        SELECT
            "country_code",
            "country_name",
            SUM("population") AS population_under_20
        FROM
            CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION_AGESPECIFIC"
        WHERE
            "year" = 2020
            AND "age" < 20
        GROUP BY
            "country_code",
            "country_name"
    ) b
    ON a."country_code" = b."country_code" AND a."country_name" = b."country_name"
WHERE
    a."year" = 2020
ORDER BY
    percentage_under_20 DESC NULLS LAST,
    a."country_name" ASC
LIMIT 10;
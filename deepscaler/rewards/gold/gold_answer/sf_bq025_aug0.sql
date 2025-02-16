-- Task: Generate a list of the top 10 countries in the year 2020, ordered by the highest percentage of their population that is under 20 years old. For each country, include the total population under 20 years old (sum of populations for ages less than 20), the total midyear population, and the percentage of the population that is under 20 years old (rounded to four decimal places).

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
-- Task: Provide a list of countries for the year 2020, including the total population under 20 years old for each country, ordered by population under 20 in descending order. Limit the output to top 100 countries.
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
ORDER BY
    population_under_20 DESC
LIMIT 100;
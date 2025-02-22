-- Task: Which country has the highest total population under the age of 25 in 2017?
SELECT "country_name", SUM("population") AS "population_under_25"
FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
WHERE "year" = 2017 AND "age" < 25
GROUP BY "country_name"
ORDER BY "population_under_25" DESC
LIMIT 1;
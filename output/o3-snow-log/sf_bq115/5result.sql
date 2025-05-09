SELECT
    "country_name",
    "country_code",
    ROUND(100.0 * POP_UNDER25 / POP_TOTAL, 4) AS "pct_population_under_25"
FROM (
    SELECT
        "country_name",
        "country_code",
        SUM(CASE WHEN "age" BETWEEN 0 AND 24 THEN "population" END) AS POP_UNDER25,
        SUM("population") AS POP_TOTAL
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
    WHERE "year" = 2017
    GROUP BY "country_name", "country_code"
) AGE_STATS
WHERE POP_TOTAL > 0
ORDER BY "pct_population_under_25" DESC NULLS LAST
LIMIT 1;
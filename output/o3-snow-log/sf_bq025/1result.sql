WITH total_population AS (
    SELECT 
        "country_code",
        SUM("population") AS total_population
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
    WHERE "year" = 2020
    GROUP BY "country_code"
),
under20_population AS (
    SELECT
        "country_code",
        SUM("population") AS population_under20
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
    WHERE "year" = 2020
      AND "age" BETWEEN 0 AND 19
    GROUP BY "country_code"
)
SELECT
    u."country_code",
    c."country_name",
    u.population_under20                  AS "population_under_20",
    t.total_population                    AS "total_midyear_population",
    ROUND(u.population_under20 * 100.0 / NULLIF(t.total_population, 0), 2) 
                                           AS "pct_population_under_20"
FROM under20_population u
JOIN total_population t 
      ON u."country_code" = t."country_code"
LEFT JOIN CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.COUNTRY_NAMES_AREA c
      ON c."country_code" = u."country_code"
ORDER BY "pct_population_under_20" DESC NULLS LAST
LIMIT 10;
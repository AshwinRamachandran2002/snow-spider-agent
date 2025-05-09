WITH pop_under25 AS (
    SELECT
        "country_code",
        SUM("population") AS "pop_under25"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_AGESPECIFIC
    WHERE "year" = 2017
      AND "age" <= 24
    GROUP BY "country_code"
)
SELECT
    m."country_name",
    (p."pop_under25" / m."midyear_population") * 100 AS "pct_population_under_25"
FROM pop_under25 p
JOIN CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION m
  ON p."country_code" = m."country_code"
 AND m."year" = 2017
ORDER BY "pct_population_under_25" DESC NULLS LAST
LIMIT 1;
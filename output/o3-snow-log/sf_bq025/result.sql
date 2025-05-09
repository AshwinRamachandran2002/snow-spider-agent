WITH pop_under20 AS (
    SELECT
        "country_code",
        "country_name",
        SUM("population") AS "pop_under20"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION_AGESPECIFIC"
    WHERE "year" = 2020
      AND "age" < 20
    GROUP BY
        "country_code",
        "country_name"
)

SELECT
    p."country_code",
    p."country_name",
    p."pop_under20",
    m."midyear_population",
    ROUND(p."pop_under20" / m."midyear_population" * 100, 4) AS "percent_under20"
FROM pop_under20 p
JOIN CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION" m
  ON p."country_code" = m."country_code"
 AND m."year" = 2020
ORDER BY
    "percent_under20" DESC NULLS LAST
LIMIT 10;
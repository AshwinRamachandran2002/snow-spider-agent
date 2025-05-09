WITH pop_under20 AS (
    SELECT
        "country_code",
        "country_name",
        SUM("population") AS "pop_under20"
    FROM "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION_AGESPECIFIC"
    WHERE "year" = 2020
      AND "age" < 20
    GROUP BY
        "country_code",
        "country_name"
)

SELECT
    m."country_code",
    m."country_name",
    u."pop_under20",
    m."midyear_population"                             AS "total_population_2020",
    ROUND( (u."pop_under20" / m."midyear_population") * 100 , 4)  AS "pct_under20"
FROM pop_under20 u
JOIN "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION" m
  ON u."country_code" = m."country_code"
WHERE m."year" = 2020
ORDER BY "pct_under20" DESC NULLS LAST
LIMIT 10;
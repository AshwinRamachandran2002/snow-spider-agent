WITH under20 AS (
    /* Total population under age 20 (both sexes) per country for 2020 */
    SELECT
        "country_code",
        "country_name",
        SUM("population") AS "population_under20"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION_AGESPECIFIC"
    WHERE "year" = 2020
      AND "age" < 20
    GROUP BY
        "country_code",
        "country_name"
), total_pop AS (
    /* Mid-year population (all ages, both sexes) per country for 2020 */
    SELECT
        "country_code",
        "midyear_population"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION"
    WHERE "year" = 2020
)
SELECT
    u."country_code",
    u."country_name",
    u."population_under20",
    t."midyear_population",
    ROUND( (u."population_under20" / t."midyear_population") * 100 , 4) AS "pct_under20"
FROM under20 u
JOIN total_pop t
  ON u."country_code" = t."country_code"
ORDER BY
    "pct_under20" DESC NULLS LAST
LIMIT 10;
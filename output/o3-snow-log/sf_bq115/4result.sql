WITH under25 AS (
    SELECT
        "country_code",
        "country_name",
        SUM("midyear_population") AS pop_under25
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_5YR_AGE_SEX
    WHERE "year" = 2017
      AND "total_flag" = 'A'              -- individual 5-year age groups
      AND "age_group_indicator" = '-'
      AND "starting_age" IN (0, 5, 10, 15, 20)   -- age groups 0-24
    GROUP BY "country_code", "country_name"
),
total_pop AS (
    SELECT
        "country_code",
        "country_name",
        "midyear_population" AS total_population
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL.MIDYEAR_POPULATION_5YR_AGE_SEX
    WHERE "year" = 2017
      AND "total_flag" = '*'              -- total, all ages
      AND "age_group_indicator" = '+'
      AND "starting_age" = 0
)
SELECT
    t."country_name",
    (u.pop_under25 / t.total_population) * 100 AS pct_under25_population
FROM total_pop t
JOIN under25 u
  ON t."country_code" = u."country_code"
ORDER BY pct_under25_population DESC NULLS LAST
LIMIT 1;
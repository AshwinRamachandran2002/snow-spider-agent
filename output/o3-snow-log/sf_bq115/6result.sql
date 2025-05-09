WITH age_under_25 AS (
    SELECT 
        "country_code",
        "country_name",
        SUM("midyear_population") AS population_under_25
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION_5YR_AGE_SEX"
    WHERE 
        "year" = 2017
        AND "total_flag" = 'A'               -- individual 5-year age groups
        AND "starting_age" <= 24             -- ages 0-24
    GROUP BY 
        "country_code",
        "country_name"
), total_pop AS (
    SELECT
        "country_code",
        "country_name",
        SUM("midyear_population") AS total_population
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION_5YR_AGE_SEX"
    WHERE
        "year" = 2017
        AND "total_flag" = '*'               -- total, all ages
        AND "age_group_indicator" = '+'      -- open-ended total group
        AND "starting_age" = 0
    GROUP BY
        "country_code",
        "country_name"
), pct AS (
    SELECT
        t."country_name",
        (a.population_under_25 / t.total_population) * 100 AS pct_under_25
    FROM total_pop t
    JOIN age_under_25 a
      ON a."country_code" = t."country_code"
)
SELECT 
    "country_name",
    pct_under_25
FROM pct
ORDER BY pct_under_25 DESC NULLS LAST
LIMIT 1;
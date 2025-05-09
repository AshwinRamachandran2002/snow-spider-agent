WITH "UNDER25" AS (
    SELECT
        m."country_code",
        m."country_name",
        SUM(m."midyear_population") AS "pop_under25"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION_5YR_AGE_SEX" m
    WHERE m."year" = 2017
      AND m."total_flag" = 'A'      -- individual 5-year age groups
      AND m."starting_age" <= 24    -- ages 0-24
    GROUP BY m."country_code", m."country_name"
),
"TOTALPOP" AS (
    SELECT
        p."country_code",
        p."country_name",
        p."midyear_population" AS "total_population"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION" p
    WHERE p."year" = 2017
)
SELECT
    t."country_name",
    (u."pop_under25" / t."total_population") * 100 AS "percent_under25"
FROM "TOTALPOP" t
JOIN "UNDER25" u
  ON t."country_code" = u."country_code"
ORDER BY "percent_under25" DESC NULLS LAST
LIMIT 1;
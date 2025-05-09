WITH "UNDER20" AS (          -- population aged 0-19, summed across 5-year groups
    SELECT
        "country_code",
        SUM("midyear_population") AS "pop_under20"
    FROM "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION_5YR_AGE_SEX"
    WHERE "year" = 2020
      AND "total_flag" = 'A'          -- individual 5-year age-group rows
      AND "starting_age" < 20         -- age groups 0-4, 5-9, 10-14, 15-19
    GROUP BY "country_code"
),
"TOTALPOP" AS (              -- all-ages mid-year population
    SELECT
        "country_code",
        "country_name",
        "midyear_population" AS "total_pop"
    FROM "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION"
    WHERE "year" = 2020
)
SELECT
    t."country_name",
    u."pop_under20",
    t."total_pop",
    ROUND(u."pop_under20" / t."total_pop" * 100, 2) AS "pct_under20"
FROM "UNDER20" u
JOIN "TOTALPOP" t
  ON t."country_code" = u."country_code"
ORDER BY "pct_under20" DESC NULLS LAST
LIMIT 10;
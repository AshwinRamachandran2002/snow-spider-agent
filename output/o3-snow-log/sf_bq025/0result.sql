-- Top 10 countries in 2020 by share of population under 20 years old
WITH under20 AS (
    SELECT
        p."country_code",
        SUM(p."midyear_population") AS "pop_under20"   -- sum 0-19 age groups (0-4,5-9,10-14,15-19)
    FROM "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION_5YR_AGE_SEX" p
    WHERE p."year" = 2020
      AND p."total_flag" = 'A'                        -- individual 5-year age groups
      AND p."starting_age" IN (0, 5, 10, 15)          -- groups that together cover ages 0-19
    GROUP BY p."country_code"
)

SELECT
    m."country_name",
    u."pop_under20",
    m."midyear_population",
    ROUND(100.0 * u."pop_under20" / m."midyear_population", 4) AS "pct_under20"
FROM under20 u
JOIN "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."MIDYEAR_POPULATION" m
  ON u."country_code" = m."country_code"
 AND m."year" = 2020
ORDER BY "pct_under20" DESC NULLS LAST
LIMIT 10;
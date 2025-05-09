WITH "pop_under20_cte" AS (
    SELECT
        "country_code",
        "country_name",
        SUM("population")          AS "pop_under20"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION_AGESPECIFIC"
    WHERE "year" = 2020
      AND "age"  < 20
    GROUP BY
        "country_code",
        "country_name"
),
"total_pop_cte" AS (
    SELECT
        "country_code",
        "midyear_population"       AS "total_pop"
    FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."MIDYEAR_POPULATION"
    WHERE "year" = 2020
)
SELECT
    p."country_code",
    p."country_name",
    p."pop_under20",
    t."total_pop",
    ROUND( (p."pop_under20" / t."total_pop") * 100, 2) AS "pct_under20"
FROM "pop_under20_cte" p
JOIN "total_pop_cte"   t
  ON p."country_code" = t."country_code"
ORDER BY
    "pct_under20" DESC NULLS LAST
LIMIT 10;
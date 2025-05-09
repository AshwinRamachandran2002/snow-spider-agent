WITH
pop_increase AS (
    SELECT
        t1."geo_id",
        COALESCE(t2."total_pop", 0) - COALESCE(t1."total_pop", 0) AS "population_increase"
    FROM
        "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2011_5YR" AS t1
    JOIN
        "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR" AS t2
        ON t1."geo_id" = t2."geo_id"
    JOIN
        "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_NEW_YORK" AS t3
        ON t1."geo_id" = t3."geo_id"
    WHERE
        t3."county_fips_code" = '047'
        AND COALESCE(t1."total_pop", 0) > 1000
        AND COALESCE(t2."total_pop", 0) > 1000
),
pop_ranked AS (
    SELECT
        "geo_id",
        "population_increase",
        ROW_NUMBER() OVER (ORDER BY "population_increase" DESC NULLS LAST) AS pop_rank
    FROM
        pop_increase
),
income_increase AS (
    SELECT
        t1."geo_id",
        COALESCE(t2."median_income", 0.0) - COALESCE(t1."median_income", 0.0) AS "median_income_increase"
    FROM
        "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2011_5YR" AS t1
    JOIN
        "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR" AS t2
        ON t1."geo_id" = t2."geo_id"
    JOIN
        "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_NEW_YORK" AS t3
        ON t1."geo_id" = t3."geo_id"
    WHERE
        t3."county_fips_code" = '047'
        AND COALESCE(t1."total_pop", 0) > 1000
        AND COALESCE(t2."total_pop", 0) > 1000
        AND t1."median_income" IS NOT NULL
        AND t2."median_income" IS NOT NULL
),
income_ranked AS (
    SELECT
        "geo_id",
        "median_income_increase",
        ROW_NUMBER() OVER (ORDER BY "median_income_increase" DESC NULLS LAST) AS income_rank
    FROM
        income_increase
),
top20_pop AS (
    SELECT * FROM pop_ranked WHERE pop_rank <= 20
),
top20_income AS (
    SELECT * FROM income_ranked WHERE income_rank <= 20
)
SELECT
    tp."geo_id" AS "tract_id",
    t3."tract_name",
    ROUND(tp."population_increase", 4) AS "population_increase",
    ROUND(ti."median_income_increase", 4) AS "median_income_increase"
FROM
    top20_pop tp
JOIN
    top20_income ti
ON
    tp."geo_id" = ti."geo_id"
JOIN
    "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_NEW_YORK" t3
ON
    tp."geo_id" = t3."geo_id"
ORDER BY
    tp."population_increase" DESC NULLS LAST
LIMIT 100;
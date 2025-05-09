WITH
/* 2011 tract-level figures for Kings County (FIPS 36047) */
tract_2011 AS (
    SELECT
        "geo_id"            AS "tract_id",
        "total_pop"         AS "pop_2011",
        "median_income"     AS "median_income_2011"
    FROM "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2011_5YR"
    WHERE "geo_id" LIKE '36047%'
),
/* 2018 figures – aggregate block-groups up to the 11-digit tract id */
tract_2018 AS (
    SELECT
        SUBSTRING("geo_id",1,11)       AS "tract_id",
        SUM("total_pop")               AS "pop_2018",
        AVG("median_income")           AS "median_income_2018"
    FROM "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."BLOCKGROUP_2018_5YR"
    WHERE "geo_id" LIKE '36047%'
    GROUP BY 1
),
/* Join years & calculate changes; keep tracts with >1 000 residents in both years */
joined AS (
    SELECT
        t11."tract_id",
        t11."pop_2011",
        t18."pop_2018",
        (t18."pop_2018" - t11."pop_2011") * 100.0 / t11."pop_2011"  AS "pct_pop_change",
        t11."median_income_2011",
        t18."median_income_2018",
        (t18."median_income_2018" - t11."median_income_2011")       AS "abs_income_change"
    FROM tract_2011 t11
    JOIN tract_2018 t18
      ON t11."tract_id" = t18."tract_id"
    WHERE t11."pop_2011" > 1000
      AND t18."pop_2018" > 1000
),
/* Top-20 tracts by % population growth */
pop_rank AS (
    SELECT "tract_id"
    FROM joined
    ORDER BY "pct_pop_change" DESC NULLS LAST
    LIMIT 20
),
/* Top-20 tracts by absolute median-income growth */
income_rank AS (
    SELECT "tract_id"
    FROM joined
    WHERE "median_income_2011" IS NOT NULL
      AND "median_income_2018" IS NOT NULL
    ORDER BY "abs_income_change" DESC NULLS LAST
    LIMIT 20
),
/* Tracts appearing in both top-20 lists */
intersection AS (
    SELECT DISTINCT p."tract_id"
    FROM pop_rank p
    JOIN income_rank i
      ON p."tract_id" = i."tract_id"
)
/* Final answer with full metrics for those tracts */
SELECT
    j."tract_id",
    j."pop_2011",
    j."pop_2018",
    ROUND(j."pct_pop_change", 2)    AS "pct_pop_change",
    j."median_income_2011",
    j."median_income_2018",
    j."abs_income_change"
FROM joined j
JOIN intersection s
  ON j."tract_id" = s."tract_id"
ORDER BY j."tract_id";
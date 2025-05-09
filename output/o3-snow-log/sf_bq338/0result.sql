/* ---------------------------------------------------------------------------
   Kings County (FIPS 36047) census-tracts that are simultaneously
   • in the Top-20 for % population growth (2011 → 2018)
   • in the Top-20 for absolute increase in median household income (2011 → 2018)
   • and had more than 1,000 residents in both 2011 & 2018
   ---------------------------------------------------------------------------*/
WITH
/* ---------- 2011 tract-level data -----------------------------------------*/
tract11_pop AS (
    SELECT
        "geo_id"      AS "tract_id",
        "total_pop"   AS "pop_2011"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2011_5YR
    WHERE "geo_id" LIKE '36047%'           -- Kings County
),
tract11_inc AS (
    SELECT
        "geo_id"        AS "tract_id",
        "median_income" AS "inc_2011"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2011_5YR
    WHERE "geo_id" LIKE '36047%'
),

/* ---------- 2018 tract-level data (aggregated from block-groups) -----------*/
tract18_pop AS (
    SELECT
        SUBSTR("geo_id", 1, 11) AS "tract_id",
        SUM("total_pop")        AS "pop_2018"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" LIKE '36047%'
    GROUP BY 1
),
tract18_inc AS (
    SELECT
        SUBSTR("geo_id", 1, 11) AS "tract_id",
        AVG("median_income")    AS "inc_2018"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" LIKE '36047%'
    GROUP BY 1
),

/* ---------- Combine & compute change metrics ------------------------------*/
metrics AS (
    SELECT
        p11."tract_id",
        p11."pop_2011",
        p18."pop_2018",
        (p18."pop_2018" - p11."pop_2011") / p11."pop_2011" * 100         AS "pct_pop_increase",
        i11."inc_2011",
        i18."inc_2018",
        i18."inc_2018" - i11."inc_2011"                                   AS "abs_inc_increase"
    FROM tract11_pop  p11
    JOIN tract18_pop  p18 ON p11."tract_id" = p18."tract_id"
    JOIN tract11_inc  i11 ON p11."tract_id" = i11."tract_id"
    JOIN tract18_inc  i18 ON p11."tract_id" = i18."tract_id"
    WHERE p11."pop_2011" > 1000
      AND p18."pop_2018" > 1000
      AND i11."inc_2011"  IS NOT NULL
      AND i18."inc_2018"  IS NOT NULL
),

/* ---------- Rank by population-growth % -----------------------------------*/
pop_ranks AS (
    SELECT
        "tract_id",
        "pct_pop_increase",
        ROW_NUMBER() OVER (ORDER BY "pct_pop_increase" DESC NULLS LAST) AS "pop_rank"
    FROM metrics
),

/* ---------- Rank by absolute income increase ------------------------------*/
inc_ranks AS (
    SELECT
        "tract_id",
        "abs_inc_increase",
        ROW_NUMBER() OVER (ORDER BY "abs_inc_increase" DESC NULLS LAST) AS "inc_rank"
    FROM metrics
)

/* ---------- Intersection of Top-20 lists ----------------------------------*/
SELECT
    p."tract_id",
    ROUND(p."pct_pop_increase", 4)  AS "pct_pop_increase",
    ROUND(i."abs_inc_increase", 2)  AS "abs_income_increase",
    p."pop_rank",
    i."inc_rank"
FROM   pop_ranks p
JOIN   inc_ranks i   ON p."tract_id" = i."tract_id"
WHERE  p."pop_rank" <= 20
  AND  i."inc_rank" <= 20
ORDER  BY p."pct_pop_increase" DESC NULLS LAST;
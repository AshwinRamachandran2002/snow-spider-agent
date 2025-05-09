WITH
/* ---------- 2018 data aggregated from block-groups to tract ---------- */
tract_2018 AS (
    SELECT
        SUBSTR("geo_id",1,11)                        AS "tract_id",
        SUM("total_pop")                             AS "pop_2018",
        AVG("median_income")                         AS "income_2018"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" LIKE '36047%'                    -- Kings County, NY
    GROUP BY SUBSTR("geo_id",1,11)
),
/* ---------- 2011 tract-level data ---------- */
tract_2011 AS (
    SELECT
        "geo_id"                                     AS "tract_id",
        "total_pop"                                  AS "pop_2011",
        "median_income"                              AS "income_2011"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2011_5YR
    WHERE "geo_id" LIKE '36047%'
),
/* ---------- combine 2011 & 2018, compute changes ---------- */
combined AS (
    SELECT
        t11."tract_id",
        t11."pop_2011",
        t18."pop_2018",
        t11."income_2011",
        t18."income_2018",
        (t18."pop_2018"   - t11."pop_2011")
        / NULLIF(t11."pop_2011",0) * 100             AS "pct_pop_change",
        (t18."income_2018" - t11."income_2011")      AS "income_change"
    FROM tract_2011 t11
    JOIN tract_2018 t18
      ON t11."tract_id" = t18."tract_id"
    WHERE t11."pop_2011" > 1000
      AND t18."pop_2018" > 1000
),
/* ---------- top-20 by % population increase ---------- */
pop_top AS (
    SELECT "tract_id"
    FROM combined
    ORDER BY "pct_pop_change" DESC NULLS LAST
    LIMIT 20
),
/* ---------- top-20 by absolute income increase ---------- */
inc_top AS (
    SELECT "tract_id"
    FROM combined
    ORDER BY "income_change" DESC NULLS LAST
    LIMIT 20
)
/* ---------- intersection: tracts meeting both criteria ---------- */
SELECT DISTINCT p."tract_id"
FROM pop_top p
JOIN inc_top i
  ON p."tract_id" = i."tract_id"
ORDER BY p."tract_id";
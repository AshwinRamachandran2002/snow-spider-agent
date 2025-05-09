/*  Tracts in Kings County (FIPS 36047) that
    1) had >1,000 residents in both 2011 & 2018,
    2) rank within the 20 largest %-population increases (2011→2018),
    3) rank within the 20 largest absolute $-income increases (2011→2018).
*/
WITH
/* ---------- 2011 tract-level data ---------- */
tract_2011 AS (
    SELECT
        "geo_id"        AS "tract_id",
        "total_pop"     AS "pop_2011",
        "median_income" AS "inc_2011"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS."CENSUSTRACT_2011_5YR"
    WHERE "geo_id" LIKE '36047%'          -- Kings County
      AND "total_pop"      > 1000         -- >1k residents in 2011
      AND "median_income" IS NOT NULL
),
/* ---------- 2018 tract-level data (built from block-groups) ---------- */
tract_2018 AS (
    SELECT
        SUBSTR("geo_id",1,11)                                       AS "tract_id",
        SUM("total_pop")                                            AS "pop_2018",
        SUM("median_income" * "total_pop") /
        NULLIF(SUM("total_pop"),0)                                  AS "inc_2018"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS."BLOCKGROUP_2018_5YR"
    WHERE "geo_id" LIKE '36047%'
    GROUP BY SUBSTR("geo_id",1,11)
    HAVING SUM("total_pop")  > 1000            -- >1k residents in 2018
       AND SUM("median_income" * "total_pop") IS NOT NULL
),
/* ---------- Combine years & compute changes ---------- */
combined AS (
    SELECT
        t11."tract_id",
        t11."pop_2011",
        t18."pop_2018",
        (t18."pop_2018" - t11."pop_2011") * 100.0 / t11."pop_2011"  AS "pct_pop_change",
        t11."inc_2011",
        t18."inc_2018",
        t18."inc_2018" - t11."inc_2011"                             AS "abs_inc_change"
    FROM tract_2011 t11
    JOIN tract_2018 t18 USING ("tract_id")
),
/* ---------- Rank tracts by %-population growth ---------- */
rank_pop AS (
    SELECT
        "tract_id",
        ROW_NUMBER() OVER (ORDER BY "pct_pop_change" DESC NULLS LAST) AS "pop_rank"
    FROM combined
),
/* ---------- Rank tracts by $-income growth ---------- */
rank_inc AS (
    SELECT
        "tract_id",
        ROW_NUMBER() OVER (ORDER BY "abs_inc_change" DESC NULLS LAST) AS "inc_rank"
    FROM combined
),
/* ---------- Keep tracts in top-20 of BOTH lists ---------- */
winners AS (
    SELECT c.*
    FROM combined  c
    JOIN rank_pop  p USING ("tract_id")
    JOIN rank_inc  i USING ("tract_id")
    WHERE p."pop_rank" <= 20
      AND i."inc_rank" <= 20
)
/* ---------- Final result ---------- */
SELECT
    "tract_id",
    "pop_2011",
    "pop_2018",
    ROUND("pct_pop_change", 6) AS "pct_pop_change",
    "inc_2011",
    "inc_2018",
    ROUND("abs_inc_change", 2) AS "abs_inc_change"
FROM winners
ORDER BY "pct_pop_change" DESC;
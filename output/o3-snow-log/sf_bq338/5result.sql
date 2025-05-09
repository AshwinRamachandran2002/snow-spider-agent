/* ----------------------------------------------------------
   Kings County (FIPS 36047) – tracts that are simultaneously
   • Top-20 in % population growth (2011 → 2018)
   • Top-20 in absolute median-income growth (2011 → 2018)
   • >1 000 residents in both 2011 & 2018
   ---------------------------------------------------------- */
WITH
/* ---------- 2011 tract-level figures (already at tract granularity) -------- */
t11 AS (
    SELECT
        "geo_id"                                   AS tract_id,
        "total_pop"                                AS pop_2011,
        "median_income"                            AS income_2011
    FROM   CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.CENSUSTRACT_2011_5YR
    WHERE  "geo_id" LIKE '36047%'                  -- Kings County
),
/* ---------- 2018 figures aggregated from block-groups ---------------------- */
t18 AS (
    SELECT
        SUBSTR("geo_id",1,11)                      AS tract_id,
        SUM("total_pop")                           AS pop_2018,
        SUM("median_income" * "total_pop")
            / NULLIF(SUM("total_pop"),0)           AS income_2018
    FROM   CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE  "geo_id" LIKE '36047%'
    GROUP  BY SUBSTR("geo_id",1,11)
),
/* ---------- Join years & compute changes; keep tracts >1 000 pop ----------- */
base AS (
    SELECT
        t11.tract_id,
        t11.pop_2011,
        t18.pop_2018,
        (t18.pop_2018 - t11.pop_2011)                              AS abs_pop_change,
        (t18.pop_2018 - t11.pop_2011) * 100.0 / t11.pop_2011       AS pct_pop_change,
        t11.income_2011,
        t18.income_2018,
        (t18.income_2018 - t11.income_2011)                        AS abs_income_change
    FROM   t11
    JOIN   t18 USING (tract_id)
    WHERE  t11.pop_2011 > 1000
      AND  t18.pop_2018 > 1000
),
/* ---------- Rank tracts on each criterion --------------------------------- */
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY pct_pop_change DESC NULLS LAST)    AS rn_pct,
        ROW_NUMBER() OVER (ORDER BY abs_income_change DESC NULLS LAST) AS rn_inc
    FROM   base
)
/* ---------- Tracts in both top-20 lists ----------------------------------- */
SELECT
    tract_id,
    pop_2011,
    pop_2018,
    pct_pop_change,
    abs_income_change,
    income_2011,
    income_2018
FROM   ranked
WHERE  rn_pct <= 20
  AND  rn_inc <= 20
ORDER BY pct_pop_change DESC NULLS LAST;
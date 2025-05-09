/* top‑3 states with the smallest 2017 adjusted non‑labor‑force population */
WITH 

/* ---------- 2017 tract–level labour variables ---------- */
t17 AS (
    SELECT
        "geo_id",
        SUBSTR("geo_id",1,2)            AS state_fips,
        /* clamp negatives to zero */
        GREATEST( 
            COALESCE("unemployed_pop",0)
          + COALESCE("not_in_labor_force",0)
          - COALESCE("group_quarters",0)
        ,0)                             AS adj_nlf,
        COALESCE("total_pop",0)         AS total_pop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR
    WHERE "total_pop" IS NOT NULL
),

/* ---------- 2015 & 2018 median income to get change ---------- */
inc15 AS (
    SELECT "geo_id", "median_income" AS med15
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR
),
inc18 AS (
    SELECT "geo_id", "median_income" AS med18
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR
),

/* ---------- join income & 2017 data ---------- */
tract AS (
    SELECT
        t17.state_fips,
        t17.adj_nlf,
        t17.total_pop,
        (inc18.med18 - inc15.med15) AS income_change,
        CASE WHEN t17.total_pop > 0
             THEN t17.adj_nlf / t17.total_pop
        END                         AS prop_adj
    FROM t17
    JOIN inc15 ON inc15."geo_id" = t17."geo_id"
    JOIN inc18 ON inc18."geo_id" = t17."geo_id"
    WHERE inc15.med15 IS NOT NULL
      AND inc18.med18 IS NOT NULL
),

/* ---------- aggregate to state level ---------- */
state_agg AS (
    SELECT
        s."postal_code"                         AS state_abbr,
        SUM(tract.income_change)                AS total_income_change,
        SUM(tract.adj_nlf)                      AS total_adj_nlf,
        AVG(tract.prop_adj)                     AS avg_adj_prop
    FROM tract
    /* map 2‑digit FIPS to postal abbreviation */
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS  s
      ON LPAD( CAST(s."fips" AS VARCHAR), 2, '0') = tract.state_fips
    GROUP BY s."postal_code"
)

/* ---------- final result ---------- */
SELECT
    state_abbr,
    total_income_change,
    total_adj_nlf,
    avg_adj_prop
FROM   state_agg
ORDER  BY total_adj_nlf ASC
LIMIT 3;
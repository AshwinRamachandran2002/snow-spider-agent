WITH
/* ──────────────────────────────────────────────────────────────
   1.  2017 TRACT–LEVEL VALUES
   ───────────────────────────────────────────────────────────── */
t2017 AS (
    SELECT
        "geo_id",
        SUBSTR("geo_id",1,2)                           AS state_fips,
        GREATEST(
            COALESCE("unemployed_pop",0)
          + COALESCE("not_in_labor_force",0)
          - COALESCE("group_quarters",0)
        ,0)                                            AS adj_non_labor_force,
        COALESCE("total_pop",0)                        AS total_pop,
        CASE
            WHEN COALESCE("total_pop",0) > 0
            THEN GREATEST(
                     COALESCE("unemployed_pop",0)
                   + COALESCE("not_in_labor_force",0)
                   - COALESCE("group_quarters",0)
                 ,0
                 ) / "total_pop"
        END                                            AS tract_prop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2017_5YR"
),

/* ──────────────────────────────────────────────────────────────
   2.  MEDIAN‑INCOME CHANGE 2015 → 2018  (tract level)
   ───────────────────────────────────────────────────────────── */
income_diff AS (
    SELECT
        a."geo_id",
        SUBSTR(a."geo_id",1,2)                         AS state_fips,
        a."median_income" - b."median_income"          AS income_change
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR" a
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR" b
          ON a."geo_id" = b."geo_id"
    WHERE a."median_income" IS NOT NULL
      AND b."median_income" IS NOT NULL
),

/* ──────────────────────────────────────────────────────────────
   3.  STATE‑LEVEL AGGREGATION
   ───────────────────────────────────────────────────────────── */
state_agg AS (
    SELECT
        s."state"                                      AS state_abbrev,
        SUM(id.income_change)                          AS total_median_income_change_2015_2018,
        SUM(t.adj_non_labor_force)                     AS total_adjusted_non_labor_force,
        AVG(t.tract_prop)                              AS avg_population_adjusted_proportion
    FROM t2017 t
    JOIN income_diff id
          ON id."geo_id" = t."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."STATES" s
          ON s."state_fips_code" = t.state_fips
    GROUP BY s."state"
)

/* ──────────────────────────────────────────────────────────────
   4.  TOP‑3 STATES WITH SMALLEST ADJUSTED NON‑LABOR FORCE
   ───────────────────────────────────────────────────────────── */
SELECT
    state_abbrev,
    total_median_income_change_2015_2018,
    total_adjusted_non_labor_force,
    avg_population_adjusted_proportion
FROM state_agg
ORDER BY total_adjusted_non_labor_force ASC
LIMIT 3;
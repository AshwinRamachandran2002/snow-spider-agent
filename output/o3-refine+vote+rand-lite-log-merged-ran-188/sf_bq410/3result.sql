WITH
-- 2017 tract‑level data needed for labour‑force metrics
tract17 AS (
    SELECT
        "geo_id",
        "unemployed_pop",
        "not_in_labor_force",
        "group_quarters",
        "total_pop"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR
),

-- 2015 median income
income15 AS (
    SELECT
        "geo_id",
        "median_income"            AS med15
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR
),

-- 2018 median income
income18 AS (
    SELECT
        "geo_id",
        "median_income"            AS med18
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR
),

-- state‑code lookup
state_map AS (
    SELECT
        "state_fips_code"          AS state_fips,
        "state"                    AS state_abbr
    FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.STATES
),

-- combine tract data with calculated adjusted non‑labour‑force metrics
tract_calc AS (
    SELECT
        t."geo_id",
        LEFT(t."geo_id", 2)                                    AS state_fips,
        GREATEST( COALESCE(t."unemployed_pop",0)
                + COALESCE(t."not_in_labor_force",0)
                - COALESCE(t."group_quarters",0), 0)           AS adj_non_labor_force,
        CASE
             WHEN COALESCE(t."total_pop",0) > 0
             THEN GREATEST( COALESCE(t."unemployed_pop",0)
                         + COALESCE(t."not_in_labor_force",0)
                         - COALESCE(t."group_quarters",0), 0)
                  / t."total_pop"
        END                                                   AS adj_prop
    FROM tract17 t
)

-- final aggregation
SELECT
    sm.state_abbr                                                    AS state,
    SUM(i18.med18 - i15.med15)                                       AS total_median_income_change_2015_2018,
    SUM(tc.adj_non_labor_force)                                      AS total_adjusted_non_labor_force,
    AVG(tc.adj_prop)                                                 AS avg_adjusted_non_labor_force_proportion
FROM tract_calc      tc
JOIN income15        i15 ON tc."geo_id" = i15."geo_id"
JOIN income18        i18 ON tc."geo_id" = i18."geo_id"
JOIN state_map       sm  ON tc.state_fips = sm.state_fips
WHERE i15.med15 IS NOT NULL
  AND i18.med18 IS NOT NULL
GROUP BY sm.state_abbr
ORDER BY total_adjusted_non_labor_force ASC NULLS LAST,
         state
LIMIT 3;
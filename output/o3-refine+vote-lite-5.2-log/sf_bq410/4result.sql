WITH

/* 2017 tract‑level figures needed for the adjustment */
tract17 AS (
    SELECT
        "geo_id",
        COALESCE("unemployed_pop",0)            AS unemployed,
        COALESCE("not_in_labor_force",0)        AS not_labor_force,
        COALESCE("group_quarters",0)            AS group_quarters,
        COALESCE("total_pop",0)                 AS total_pop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2017_5YR"
),

/* 2015 median income */
tract15 AS (
    SELECT
        "geo_id",
        "median_income"                         AS med_2015
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR"
),

/* 2018 median income */
tract18 AS (
    SELECT
        "geo_id",
        "median_income"                         AS med_2018
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR"
),

/* join the three vintages, keep only tracts having both income values */
joined AS (
    SELECT
        t17.*,
        t15.med_2015,
        t18.med_2018,
        SUBSTR(t17."geo_id",1,2)               AS state_fips
    FROM tract17 t17
    INNER JOIN tract15 t15  ON t17."geo_id" = t15."geo_id"
    INNER JOIN tract18 t18  ON t17."geo_id" = t18."geo_id"
),

/* calculate tract‑level metrics */
calc AS (
    SELECT
        state_fips,
        /* adjusted non‑labor‑force population, clamped at zero */
        GREATEST(unemployed + not_labor_force - group_quarters , 0)      AS adj_nlf,
        total_pop,
        /* income change 2018‑2015 */
        (med_2018 - med_2015)                                            AS income_diff,
        /* tract‑level proportion */
        CASE WHEN total_pop > 0
             THEN GREATEST(unemployed + not_labor_force - group_quarters , 0)::FLOAT
                  / total_pop
        END                                                              AS proportion
    FROM joined
)

/* aggregate to state level and pick the 3 states with the smallest totals */
SELECT
    st."state"                                            AS state_abbr,
    SUM(income_diff)                                      AS total_income_change_2015_2018,
    SUM(adj_nlf)                                          AS total_adjusted_non_labor_force,
    AVG(proportion)                                       AS avg_adjusted_proportion
FROM calc c
JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."STATES" st
  ON st."state_fips_code" = c.state_fips
GROUP BY st."state"
ORDER BY total_adjusted_non_labor_force ASC NULLS LAST,
         st."state"
LIMIT 3;
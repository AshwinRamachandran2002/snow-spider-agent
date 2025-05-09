WITH tract_2017 AS (   -- 2017 tract‑level data we will aggregate on
    SELECT
        "geo_id",
        COALESCE("unemployed_pop",0)        AS unemployed,
        COALESCE("not_in_labor_force",0)    AS not_lf,
        COALESCE("group_quarters",0)        AS gq,
        COALESCE("total_pop",0)             AS tot_pop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR
),

income_2015 AS (        -- 2015 tract median income
    SELECT
        "geo_id",
        "median_income" AS med_inc_2015
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR
),

income_2018 AS (        -- 2018 tract median income
    SELECT
        "geo_id",
        "median_income" AS med_inc_2018
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR
),

tract_combined AS (     -- combine 2015, 2017, 2018 information
    SELECT
        t.*,
        i15.med_inc_2015,
        i18.med_inc_2018,
        -- adjusted non‑labor‑force population (clamped to ≥0)
        GREATEST(   t.unemployed + t.not_lf - t.gq , 0)      AS adj_nlf
    FROM tract_2017 t
    LEFT JOIN income_2015 i15 ON i15."geo_id" = t."geo_id"
    LEFT JOIN income_2018 i18 ON i18."geo_id" = t."geo_id"
    WHERE i15.med_inc_2015 IS NOT NULL         -- exclude tracts w/ missing income
      AND i18.med_inc_2018 IS NOT NULL
),

state_aggregates AS (   -- aggregate to state level
    SELECT
        SUBSTR("geo_id",1,2)                       AS state_fips,
        SUM( med_inc_2018 - med_inc_2015 )         AS total_median_income_change,
        SUM( adj_nlf )                             AS total_adjusted_nlf,
        AVG( CASE WHEN tot_pop > 0 THEN adj_nlf / tot_pop END )  AS avg_adj_nlf_ratio
    FROM tract_combined
    GROUP BY state_fips
),

states AS (             -- look up state postal abbreviations
    SELECT
        "state_fips_code"  AS state_fips,
        "state"            AS state_abbrev
    FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.STATES
)

SELECT
    s.state_abbrev                                 AS "state_abbrev",
    a.total_median_income_change                   AS "total_median_income_change",
    a.total_adjusted_nlf                           AS "total_adjusted_non_labor_force",
    a.avg_adj_nlf_ratio                            AS "avg_population_adjusted_proportion"
FROM state_aggregates a
JOIN states        s USING (state_fips)
ORDER BY a.total_adjusted_nlf ASC
LIMIT 3;
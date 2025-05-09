/*  Count counties that (a) saw unemployment rise between the 2015 and 2018
    5-year ACS snapshots and (b) had fewer dual–eligible enrollees on
    2018-12-01 than on 2015-12-01.                                   */
WITH unemployment_by_county AS (          -- 5-year ACS unemployment
    SELECT
        "geo_id"                             AS county_key,          -- FIPS / county identifier
        SUM( CASE WHEN DATE_PART(year,"do_date") = 2015
                  THEN COALESCE("unemployed_pop",0) END )  AS u2015,
        SUM( CASE WHEN DATE_PART(year,"do_date") = 2018
                  THEN COALESCE("unemployed_pop",0) END )  AS u2018
    FROM   SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"
    WHERE  DATE_PART(year,"do_date") IN (2015, 2018)
    GROUP  BY "geo_id"
),
unemployment_increase AS (               -- keep only counties with ↑ unemployment
    SELECT county_key
    FROM   unemployment_by_county
    WHERE  u2018 > u2015
),
dual_by_county AS (                      -- Dual–eligible counts
    SELECT
        UPPER(TRIM("County_Name"))        AS county_key,            -- normalised join key
        SUM( CASE WHEN "Date" = '2015-12-01'
                  THEN COALESCE("Public_Total",0) END ) AS d2015,
        SUM( CASE WHEN "Date" = '2018-12-01'
                  THEN COALESCE("Public_Total",0) END ) AS d2018
    FROM   SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT."DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM"
    WHERE  "Date" IN ('2015-12-01','2018-12-01')
    GROUP  BY UPPER(TRIM("County_Name"))
),
dual_decrease AS (                       -- keep only counties with ↓ enrollment
    SELECT county_key
    FROM   dual_by_county
    WHERE  d2018 < d2015
)
--  Final count: intersection of the two condition sets
SELECT COUNT(*) AS "county_count"
FROM   unemployment_increase  ui
JOIN   dual_decrease          dd
  ON   ui.county_key = dd.county_key;
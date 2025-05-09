/*  Top-10 counties (ACS 2017 5-YR) with the largest counts of SNAP-participating
    households that also appear in the 2017-01-01 SNAP-enrollment file.         */

WITH county_acs_2017 AS (          -- 2017 5-year ACS county-level data
    SELECT
        SUBSTRING("geo_id", -5)                               AS county_fips ,
        "households_public_asst_or_food_stamps"               AS snap_households ,
        COALESCE("income_less_10000",0)
      + COALESCE("income_10000_14999",0)
      + COALESCE("income_15000_19999",0)                      AS under20k_households
    FROM  SDOH.CENSUS_BUREAU_ACS.COUNTY_2017_5YR
),

snap_enrollment_2017 AS (          -- SNAP enrollment on 2017-01-01
    SELECT
        LPAD(SUBSTRING("GeoDesc",1,5),5,'0')                  AS county_fips ,
        SUM("SNAP_All_Participation_Persons")                 AS snap_persons
    FROM  SDOH.SDOH_SNAP_ENROLLMENT.SNAP_ENROLLMENT
    WHERE "Date" = '2017-01-01'
    GROUP BY county_fips
),

combined AS (                      -- merge ACS & SNAP data, keep positive SNAP households
    SELECT
        a.county_fips ,
        a.snap_households ,
        a.under20k_households
    FROM   county_acs_2017  a
    JOIN   snap_enrollment_2017  e
           ON a.county_fips = e.county_fips
    WHERE  a.snap_households > 0
)

SELECT
    county_fips ,
    snap_households ,
    under20k_households ,
    ROUND( under20k_households / NULLIF(snap_households,0) , 4)
        AS under20k_to_snap_ratio
FROM   combined
ORDER BY snap_households DESC NULLS LAST
LIMIT 10;
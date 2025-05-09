/*  Top 10 counties with the largest number of SNAP-participating households
    (ACS 2017 5-year estimates) that also appear in the January-1-2017
    SNAP-enrollment file.  For every county the ratio of households with
    incomes below $20 000 to total SNAP-participating households is shown.
*/

WITH snap_enrollment_2017 AS (          --  SNAP data (people) on 2017-01-01
    SELECT
        SUBSTR("GeoDesc",1,5)                    AS county_fips,
        SUM("SNAP_All_Participation_Persons")    AS snap_persons
    FROM   SDOH.SDOH_SNAP_ENROLLMENT.SNAP_ENROLLMENT
    WHERE  "Date" = '2017-01-01'
    GROUP  BY SUBSTR("GeoDesc",1,5)
    HAVING SUM("SNAP_All_Participation_Persons") > 0
),

county_acs_2017 AS (                   --  2017 ACS 5-year county-level data
    SELECT
        "geo_id",
        RIGHT("geo_id",5)                               AS county_fips,
        "households_public_asst_or_food_stamps"         AS snap_households,
        COALESCE("income_less_10000",0)
      + COALESCE("income_10000_14999",0)
      + COALESCE("income_15000_19999",0)                AS hh_under_20000
    FROM   SDOH.CENSUS_BUREAU_ACS.COUNTY_2017_5YR
)

SELECT
    acs."geo_id"                                         AS county_geo_id,
    acs.snap_households                                  AS total_snap_participating_households,
    ROUND(acs.hh_under_20000 / NULLIF(acs.snap_households,0), 4)
                                                         AS under_20k_to_snap_ratio
FROM   county_acs_2017   acs
JOIN   snap_enrollment_2017  se
       ON acs.county_fips = se.county_fips              -- retain only counties with non-zero SNAP enrolment
ORDER  BY total_snap_participating_households DESC NULLS LAST
LIMIT  10;
/*  Count the number of counties that (a) show higher unemployment
    in the 2018 five-year ACS extract than in the 2015 extract and
    (b) show lower dual-eligible enrollee counts on 2018-12-01 than
    on 2015-12-01.                                                */

/*------------------------------------------------------------------*/
/*  1)  Unemployment change, 2015-vs-2018 – aggregated to “county”  */
/*------------------------------------------------------------------*/
WITH unemp_15 AS (      -- 2015 snapshot from the five-year ACS ZIP file
        SELECT  "geo_id"                          AS county_key,
                SUM("unemployed_pop")             AS unemp_2015
        FROM    SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR
        WHERE   "do_date" = '2015-01-01'
        GROUP BY "geo_id"
),
unemp_18 AS (      -- 2018 snapshot from the same file
        SELECT  "geo_id"                          AS county_key,
                SUM("unemployed_pop")             AS unemp_2018
        FROM    SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR
        WHERE   "do_date" = '2018-01-01'
        GROUP BY "geo_id"
),
unemp_growth AS (  -- keep only areas whose unemployment increased
        SELECT  u15.county_key
        FROM    unemp_15 u15
        JOIN    unemp_18 u18
              ON u15.county_key = u18.county_key
        WHERE   u18.unemp_2018 > u15.unemp_2015
),

/*------------------------------------------------------------------*/
/*  2)  Dual-eligible change, 2015-vs-2018 – aggregated by county    */
/*------------------------------------------------------------------*/
dual_15 AS (      -- enrollee counts for 2015-12-01
        SELECT  UPPER("County_Name")              AS county_key,
                SUM("Public_Total")               AS dual_2015
        FROM    SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT.
                DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM
        WHERE   "Date" = '2015-12-01'
        GROUP BY UPPER("County_Name")
),
dual_18 AS (      -- enrollee counts for 2018-12-01
        SELECT  UPPER("County_Name")              AS county_key,
                SUM("Public_Total")               AS dual_2018
        FROM    SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT.
                DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM
        WHERE   "Date" = '2018-12-01'
        GROUP BY UPPER("County_Name")
),
dual_decline AS ( -- keep only counties whose enrollee count declined
        SELECT  d15.county_key
        FROM    dual_15 d15
        JOIN    dual_18 d18
              ON d15.county_key = d18.county_key
        WHERE   d18.dual_2018 < d15.dual_2015
)

/*------------------------------------------------------------------*/
/*  3)  Intersection of both conditions                             */
/*------------------------------------------------------------------*/
SELECT  COUNT(*)  AS counties_meeting_both_conditions
FROM    unemp_growth   ug
JOIN    dual_decline   dd
      ON ug.county_key = dd.county_key;
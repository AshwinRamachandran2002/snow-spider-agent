/*  Count of counties whose unemployment rose (2015 ➔ 2018, ACS 5-yr)  
    AND whose dual-eligible enrollee total fell (Dec-1-2015 ➔ Dec-1-2018)  */

WITH
/* 1. Unemployment totals by county-key (geo_id) for the two target years */
unemp_2015 AS (
    SELECT
        "geo_id"                        AS county_key,
        SUM("unemployed_pop")           AS unemp_2015
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR
    WHERE EXTRACT(year FROM "do_date") = 2015
    GROUP BY "geo_id"
),
unemp_2018 AS (
    SELECT
        "geo_id"                        AS county_key,
        SUM("unemployed_pop")           AS unemp_2018
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR
    WHERE EXTRACT(year FROM "do_date") = 2018
    GROUP BY "geo_id"
),
/* 2. Counties whose unemployment increased */
inc_unemp AS (
    SELECT  u15.county_key
    FROM    unemp_2015 u15
    JOIN    unemp_2018 u18  ON u18.county_key = u15.county_key
    WHERE   u18.unemp_2018 > u15.unemp_2015
),
/* 3. Dual-eligible enrollee totals for the two specific snapshot dates */
dual_2015 AS (
    SELECT  UPPER("County_Name")        AS county_key,
            "Public_Total"              AS tot_2015
    FROM    SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT.DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM
    WHERE   "Date" = '2015-12-01'
),
dual_2018 AS (
    SELECT  UPPER("County_Name")        AS county_key,
            "Public_Total"              AS tot_2018
    FROM    SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT.DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM
    WHERE   "Date" = '2018-12-01'
),
/* 4. Counties whose dual-eligible enrollee count decreased */
dec_dual AS (
    SELECT  d15.county_key
    FROM    dual_2015 d15
    JOIN    dual_2018 d18  ON d18.county_key = d15.county_key
    WHERE   d18.tot_2018 < d15.tot_2015
),
/* 5. Counties satisfying BOTH conditions */
both_conditions AS (
    SELECT DISTINCT i.county_key
    FROM   inc_unemp i
    JOIN   dec_dual  d  ON d.county_key = i.county_key
)
SELECT COUNT(*) AS cnt_counties_increase_unemp_decrease_dual
FROM   both_conditions;
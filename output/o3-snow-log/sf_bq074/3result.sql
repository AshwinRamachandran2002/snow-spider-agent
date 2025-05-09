/* Count counties (keys) that saw unemployment rise (2015→2018) and
   dual-eligible enrolment fall (2015-12-01→2018-12-01)                  */

WITH unemp_2015 AS (          -- unemployment totals in 2015
    SELECT
        "geo_id"                               AS county_key,
        SUM("unemployed_pop")                  AS unemp_2015
    FROM SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"
    WHERE EXTRACT(YEAR FROM "do_date") = 2015
    GROUP BY "geo_id"
),
unemp_2018 AS (          -- unemployment totals in 2018
    SELECT
        "geo_id"                               AS county_key,
        SUM("unemployed_pop")                  AS unemp_2018
    FROM SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"
    WHERE EXTRACT(YEAR FROM "do_date") = 2018
    GROUP BY "geo_id"
),
unemp_increase AS (      -- keys with higher unemployment in 2018
    SELECT u18.county_key
    FROM   unemp_2015 u15
    JOIN   unemp_2018 u18 USING (county_key)
    WHERE  u18.unemp_2018 > u15.unemp_2015
),

dual_2015 AS (           -- dual-eligible totals on 2015-12-01
    SELECT
        TRIM(UPPER("County_Name"))             AS county_key,
        SUM("Public_Total")                    AS dual_2015
    FROM SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT."DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM"
    WHERE "Date" = '2015-12-01'
    GROUP BY TRIM(UPPER("County_Name"))
),
dual_2018 AS (           -- dual-eligible totals on 2018-12-01
    SELECT
        TRIM(UPPER("County_Name"))             AS county_key,
        SUM("Public_Total")                    AS dual_2018
    FROM SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT."DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM"
    WHERE "Date" = '2018-12-01'
    GROUP BY TRIM(UPPER("County_Name"))
),
dual_decrease AS (       -- keys with lower enrolment in 2018
    SELECT d18.county_key
    FROM   dual_2015 d15
    JOIN   dual_2018 d18 USING (county_key)
    WHERE  d18.dual_2018 < d15.dual_2015
)

/* final result */
SELECT
    COUNT(*) AS "cnt_counties_inc_unemp_dec_dual"
FROM unemp_increase ui
JOIN dual_decrease dd
  ON ui.county_key = dd.county_key;
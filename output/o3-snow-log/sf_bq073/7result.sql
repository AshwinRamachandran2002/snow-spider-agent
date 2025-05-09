/*-------------------------------------------------------------
  Vulnerable-worker counts by state
  -------------------------------------------------------------
  • Join the ZIP-level 2015, 2017 and 2018 ACS files so we only
    keep ZIP codes for which we can calculate a 2015-to-2018
    median-income change.
  • Attach state names through the GEO_US_BOUNDARIES.ZIP_CODES
    lookup table.
  • A worker is “vulnerable” if they are:
       – 38 % of 2017 wholesale-trade employees, or
       – 41 % of 2017 manufacturing employees.
  • Aggregate those vulnerable counts to the state level and
    list states in descending order of total vulnerable workers.
--------------------------------------------------------------*/
SELECT
    g."state_name"                                                        AS "state",
    SUM(0.38 * z17."employed_wholesale_trade")        AS "vulnerable_wholesale_trade_workers",
    SUM(0.41 * z17."employed_manufacturing")          AS "vulnerable_manufacturing_workers",
    SUM(0.38 * z17."employed_wholesale_trade")
  + SUM(0.41 * z17."employed_manufacturing")          AS "total_vulnerable_workers"
FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR"  z17
JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR"  z15
     ON z17."geo_id" = z15."geo_id"
JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR"  z18
     ON z17."geo_id" = z18."geo_id"
JOIN "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES"           g
     ON z17."geo_id" = g."zip_code"
WHERE z15."median_income" IS NOT NULL
  AND z18."median_income" IS NOT NULL
GROUP BY g."state_name"
ORDER BY "total_vulnerable_workers" DESC NULLS LAST;
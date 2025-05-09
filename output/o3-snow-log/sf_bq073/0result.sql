/* ------------------------------------------------------------
   Vulnerable-worker counts by state
   – “Vulnerable” = 38 % of 2017 wholesale-trade employment
                    + 41 % of 2017 manufacturing employment
   – Only ZIP codes that have a median-income value in BOTH
     the 2015 and 2018 ACS 5-year ZIP-level tables are kept,
     so that a 2015-to-2018 income difference could be measured.
-------------------------------------------------------------*/
SELECT
       zips_bounds."state_name"                                               AS "state_name",
       SUM(0.38 * COALESCE(zip17."employed_wholesale_trade", 0))              AS "vulnerable_wholesale_trade",
       SUM(0.41 * COALESCE(zip17."employed_manufacturing",   0))              AS "vulnerable_manufacturing",
       SUM(0.38 * COALESCE(zip17."employed_wholesale_trade", 0) +
           0.41 * COALESCE(zip17."employed_manufacturing",   0))              AS "total_vulnerable_workers"
FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  zip15
JOIN   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  zip18
       ON  zip15."geo_id" = zip18."geo_id"
JOIN   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  zip17
       ON  zip15."geo_id" = zip17."geo_id"
JOIN   CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"           zips_bounds
       ON  zip15."geo_id" = zips_bounds."zip_code"
WHERE  zip15."median_income" IS NOT NULL
  AND  zip18."median_income" IS NOT NULL
GROUP  BY zips_bounds."state_name"
ORDER  BY "total_vulnerable_workers" DESC NULLS LAST;
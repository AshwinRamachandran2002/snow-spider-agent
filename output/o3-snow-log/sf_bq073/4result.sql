SELECT
    s."state_name",
    SUM(COALESCE(z17."employed_wholesale_trade",0) * 0.38)      AS "vulnerable_wholesale_trade_workers",
    SUM(COALESCE(z17."employed_manufacturing",0)   * 0.41)      AS "vulnerable_manufacturing_workers",
    SUM(COALESCE(z17."employed_wholesale_trade",0) * 0.38) +
    SUM(COALESCE(z17."employed_manufacturing",0)   * 0.41)      AS "total_vulnerable_workers"
FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"     z15
JOIN   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"     z18
       ON z15."geo_id" = z18."geo_id"
JOIN   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"     z17
       ON z15."geo_id" = z17."geo_id"
JOIN   CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"              zmap
       ON z15."geo_id" = zmap."zip_code"
JOIN   CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."STATES"                 s
       ON zmap."state_code" = s."state"
WHERE  (z18."median_income" - z15."median_income") > 0
GROUP BY s."state_name"
ORDER BY "total_vulnerable_workers" DESC NULLS LAST;
/*---------------------------------------------------------------
  State-level count of “vulnerable” workers
  – 38 % of 2017 wholesale-trade employment
  – 41 % of 2017 manufacturing employment
  Only ZIP codes that have BOTH 2015- and 2018-income records 
  are included (income difference is calculated but not filtered).
----------------------------------------------------------------*/
SELECT
    g."state_name"                                                                     AS "state_name",
    ROUND( SUM( z17."employed_wholesale_trade" * 0.38 ), 4 )                           AS "vulnerable_wholesale_trade",
    ROUND( SUM( z17."employed_manufacturing"  * 0.41 ), 4 )                            AS "vulnerable_manufacturing",
    ROUND( SUM( (z17."employed_wholesale_trade" * 0.38)
              + (z17."employed_manufacturing"  * 0.41) ), 4 )                          AS "total_vulnerable_workers"
FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"            z17
/*–– ZIPs with income data for both 2015 & 2018 (difference computed) ––*/
JOIN (
        SELECT 
            z15."geo_id",
            ( z18."median_income" - z15."median_income" ) AS "income_change"
        FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  z15
        JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  z18
              ON z15."geo_id" = z18."geo_id"
     ) inc
       ON z17."geo_id" = inc."geo_id"
/*–– Map each ZIP code to its state ––*/
JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"                    g
      ON z17."geo_id" = g."zip_code"
GROUP BY g."state_name"
ORDER BY "total_vulnerable_workers" DESC NULLS LAST;
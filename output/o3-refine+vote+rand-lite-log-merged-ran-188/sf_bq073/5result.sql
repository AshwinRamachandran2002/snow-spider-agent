/*--------------------------------------------------------------------
  State-level counts of “vulnerable” workers (38 % of wholesale-trade
  jobs + 41 % of manufacturing jobs) using 2017 ZIP employment data.
  We keep only ZIP codes that appear in BOTH the 2015- and 2018-level
  ZIP files (proxy for having median-income data for both years).
--------------------------------------------------------------------*/
WITH income_zips AS (
    /* ZIP codes present in BOTH the 2015 and 2018 5-year ZIP tables */
    SELECT DISTINCT "geo_id"
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR
    INTERSECT
    SELECT DISTINCT "geo_id"
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR
)

SELECT
    s."state",
    SUM(0.38 * z17."employed_wholesale_trade")                                       AS "vulnerable_wholesale_trade",
    SUM(0.41 * z17."employed_manufacturing")                                         AS "vulnerable_manufacturing",
    SUM(0.38 * z17."employed_wholesale_trade" + 0.41 * z17."employed_manufacturing") AS "vulnerable_total"
FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR  z17
JOIN  income_zips  iz
      ON z17."geo_id" = iz."geo_id"                -- keep only ZIPs with 2015 & 2018 income data
JOIN  CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS     s
      ON s."fips" = TO_NUMBER(SUBSTR(z17."geo_id", 1, 2))
GROUP BY s."state"
ORDER BY "vulnerable_total" DESC NULLS LAST;
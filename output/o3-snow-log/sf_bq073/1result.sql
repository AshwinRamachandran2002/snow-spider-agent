/*  List states by vulnerable-worker totals
    (38 % of 2017 wholesale-trade jobs + 41 % of 2017 manufacturing jobs)  */

SELECT
    v."state_name",
    v."vulnerable_wholesale_trade_workers",
    v."vulnerable_manufacturing_workers",
    v."total_vulnerable_workers"
FROM (
    SELECT
        s."state_name",
        /* 38 % of wholesale-trade employment */
        SUM(0.38 * z17."employed_wholesale_trade")     AS "vulnerable_wholesale_trade_workers",
        /* 41 % of manufacturing employment */
        SUM(0.41 * z17."employed_manufacturing")       AS "vulnerable_manufacturing_workers",
        /* combined total */
        SUM(0.38 * z17."employed_wholesale_trade")
      + SUM(0.41 * z17."employed_manufacturing")       AS "total_vulnerable_workers"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"      z17
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"               s
          ON z17."geo_id" = s."zip_code"
    GROUP BY
        s."state_name"
) v
ORDER BY
    v."total_vulnerable_workers" DESC NULLS LAST;
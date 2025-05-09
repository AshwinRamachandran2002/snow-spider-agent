/*--------------------------------------------------------------------
  Vulnerable-worker counts by state
  • “Vulnerable” = 38 % of 2017 wholesale-trade employment
                   + 41 % of 2017 manufacturing employment
  • Only ZIP codes that exist in BOTH the 2015- and 2018-ACS ZIP tables
    (i.e., for which a median-income difference can be calculated)
    are considered.
--------------------------------------------------------------------*/
WITH income_diff AS (          -- ZIPs having a 2015-to-2018 income figure
    SELECT  a."geo_id",
            (b."median_income" - a."median_income") AS "median_income_diff"
    FROM    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" a
    JOIN    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" b
           ON a."geo_id" = b."geo_id"
),
vuln_zip AS (                  -- Vulnerable workers per qualifying ZIP
    SELECT  zg."state_code",
            0.38 * z17."employed_wholesale_trade"  AS "vuln_wholesale",
            0.41 * z17."employed_manufacturing"   AS "vuln_manufacturing"
    FROM    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  z17
    JOIN    income_diff                                       id
           ON z17."geo_id" = id."geo_id"
    JOIN    CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" zg
           ON z17."geo_id" = zg."zip_code"
)
SELECT  st."state_name"                                           AS "state",
        SUM(vz."vuln_wholesale")      AS "vulnerable_wholesale_trade_workers",
        SUM(vz."vuln_manufacturing")  AS "vulnerable_manufacturing_workers",
        SUM(vz."vuln_wholesale") +
        SUM(vz."vuln_manufacturing")  AS "vulnerable_workers_total"
FROM    vuln_zip                                             vz
JOIN    CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."STATES"       st
       ON vz."state_code" = st."state"        -- postal-code join
GROUP BY st."state_name"
ORDER BY "vulnerable_workers_total" DESC NULLS LAST;
/*---------------------------------------------------------------
  1)  Build a list of ZIP codes that have a NON-NULL median-income
      value in BOTH the 2015- and 2018-ACS tables
----------------------------------------------------------------*/
WITH income_diff_zip AS (
    SELECT 
        z15."geo_id" AS "zip"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" AS z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" AS z18
          ON z15."geo_id" = z18."geo_id"
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
),

/*----------------------------------------------------------------
  2)  Attach 2017 employment counts and translate ZIP → State;
      compute vulnerable-worker counts at the ZIP level
----------------------------------------------------------------*/
zip_vulnerable AS (
    SELECT
        g."state_name",
        COALESCE(z17."employed_wholesale_trade",0) * 0.38  AS "vuln_wholesale",
        COALESCE(z17."employed_manufacturing" ,0) * 0.41   AS "vuln_manufacturing"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"   AS z17
    JOIN income_diff_zip                                           AS id
          ON z17."geo_id" = id."zip"
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"         AS g
          ON z17."geo_id" = g."zip_code"
)

/*----------------------------------------------------------------
  3)  Aggregate to the state level and order by total vulnerable
----------------------------------------------------------------*/
SELECT
    "state_name",
    SUM("vuln_wholesale")     AS "vulnerable_wholesale_trade",
    SUM("vuln_manufacturing") AS "vulnerable_manufacturing",
    SUM("vuln_wholesale") + 
    SUM("vuln_manufacturing") AS "total_vulnerable_workers"
FROM zip_vulnerable
GROUP BY "state_name"
ORDER BY "total_vulnerable_workers" DESC NULLS LAST;
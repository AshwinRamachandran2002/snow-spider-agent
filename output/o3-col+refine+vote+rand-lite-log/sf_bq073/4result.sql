/* 1) ZIP codes whose median household income fell between 2015- and 2018-5YR
   2) 2017 vulnerable workers = 38 % of wholesale-trade   + 41 % of manufacturing
   3) Aggregate to state via 2-digit FIPS prefix          */
WITH income_decline_zip AS (          -- ZIPs where income declined
    SELECT  a."geo_id"
    FROM    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR"  a
    JOIN    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR"  b
           ON a."geo_id" = b."geo_id"
    WHERE   b."median_income" < a."median_income"
),
zip_vulnerable_2017 AS (              -- 2017 vulnerable‐worker counts for those ZIPs
    SELECT
        z."geo_id",
        TO_NUMBER(LEFT(z."geo_id", 2))                    AS "state_fips",
        z."employed_wholesale_trade" * 0.38              AS "vuln_wholesale",
        z."employed_manufacturing"   * 0.41              AS "vuln_manufacturing"
    FROM  "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR"  z
    JOIN  income_decline_zip  d
          ON z."geo_id" = d."geo_id"
)
SELECT
    s."state",
    SUM(z."vuln_wholesale")     AS "vulnerable_wholesale_trade",
    SUM(z."vuln_manufacturing") AS "vulnerable_manufacturing",
    SUM(z."vuln_wholesale") + 
    SUM(z."vuln_manufacturing") AS "total_vulnerable"
FROM    zip_vulnerable_2017  z
JOIN    "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS"  s
       ON z."state_fips" = s."fips"
GROUP BY s."state"
ORDER BY "total_vulnerable" DESC NULLS LAST;
WITH income_and_jobs AS (  /* 1. Gather ZIP‑level data and keep state code in uppercase alias */
    SELECT
        z17."geo_id"                                   AS ZIP_ID ,
        zb."state_code"                                AS STATE_CODE ,      -- 2‑letter code
        COALESCE(z18."median_income", 0)               AS MEDIAN_INCOME_2018 ,
        COALESCE(z15."median_income", 0)               AS MEDIAN_INCOME_2015 ,
        COALESCE(z17."employed_wholesale_trade", 0)    AS EMPLOYED_WHOLESALE ,
        COALESCE(z17."employed_manufacturing", 0)      AS EMPLOYED_MANUFACTURING
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  z17
    LEFT JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  z15
           ON  z17."geo_id" = z15."geo_id"
    LEFT JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  z18
           ON  z17."geo_id" = z18."geo_id"
    JOIN       CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"           zb
           ON  zb."zip_code" = z17."geo_id"
),

zip_level_vulnerable AS (      /* 2.  Vulnerable workers per ZIP */
    SELECT
        STATE_CODE ,
        EMPLOYED_WHOLESALE     * 0.38  AS VULN_WHOLESALE ,
        EMPLOYED_MANUFACTURING * 0.41  AS VULN_MANUFACTURING
    FROM income_and_jobs
),

state_totals AS (              /* 3.  Aggregate to state level  */
    SELECT
        f."state"                                                AS STATE_NAME ,
        ROUND( SUM( VULN_WHOLESALE     ) )  AS VULNERABLE_WHOLESALE_WORKERS ,
        ROUND( SUM( VULN_MANUFACTURING ) )  AS VULNERABLE_MANUFACTURING_WORKERS ,
        ROUND( SUM( VULN_WHOLESALE     ) +
               SUM( VULN_MANUFACTURING ) )  AS TOTAL_VULNERABLE_WORKERS
    FROM   zip_level_vulnerable      v
    JOIN   CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"  f
           ON  UPPER( v.STATE_CODE ) = f."postal_code"
    GROUP  BY f."state"
)

SELECT
    STATE_NAME ,
    VULNERABLE_WHOLESALE_WORKERS ,
    VULNERABLE_MANUFACTURING_WORKERS ,
    TOTAL_VULNERABLE_WORKERS
FROM   state_totals
ORDER  BY TOTAL_VULNERABLE_WORKERS  DESC NULLS LAST ;
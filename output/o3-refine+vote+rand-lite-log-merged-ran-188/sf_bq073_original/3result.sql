WITH income_and_jobs AS (   -- 2015 & 2018 income joined to 2017 employment
    SELECT
        z17."geo_id"                                              AS zip,
        (z18."median_income" - z15."median_income")               AS income_change_2015_2018,
        z17."employed_wholesale_trade"                            AS wholesale_emp_2017,
        z17."employed_manufacturing"                              AS manufacturing_emp_2017
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  z17
    LEFT JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" z15
           ON z17."geo_id" = z15."geo_id"
    LEFT JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" z18
           ON z17."geo_id" = z18."geo_id"
),
vulnerable_by_state AS (    -- map ZIPs to states and calculate vulnerable workers
    SELECT
        ub."state_name"                                           AS STATE_NAME,
        SUM(wholesale_emp_2017 * 0.38)  AS VULNERABLE_WHOLESALE,
        SUM(manufacturing_emp_2017 * 0.41) AS VULNERABLE_MANUFACTURING
    FROM income_and_jobs ij
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" ub
         ON ij.zip = ub."zip_code"
    GROUP BY ub."state_name"
)
SELECT
    STATE_NAME,
    ROUND(VULNERABLE_WHOLESALE)        AS VULNERABLE_WHOLESALE_WORKERS,
    ROUND(VULNERABLE_MANUFACTURING)    AS VULNERABLE_MANUFACTURING_WORKERS,
    ROUND(VULNERABLE_WHOLESALE + VULNERABLE_MANUFACTURING) AS TOTAL_VULNERABLE_WORKERS
FROM vulnerable_by_state
ORDER BY TOTAL_VULNERABLE_WORKERS DESC NULLS LAST,
         STATE_NAME;
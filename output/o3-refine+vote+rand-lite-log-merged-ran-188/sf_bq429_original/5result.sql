WITH zip_state AS (   -- ZIP‑to‑state lookup from boundary file
    SELECT 
        gz."zip_code"  ::TEXT AS zip_code ,
        gz."state_code"::TEXT AS state_code
    FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" gz
),  

/*───────────────────────────────────────────────────────────
  1. Average ZIP‑level change in median income, 2018‑2015
───────────────────────────────────────────────────────────*/
income_diff AS (     
    SELECT 
        zs.state_code,
        AVG( z18."median_income" - z15."median_income" ) AS avg_income_diff
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" z18
         ON z15."geo_id" = z18."geo_id"
    JOIN zip_state zs
         ON zs.zip_code = z15."geo_id"
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
    GROUP BY zs.state_code
),

/*───────────────────────────────────────────────────────────
  2. 2017 weighted vulnerable employment per ZIP, then average
───────────────────────────────────────────────────────────*/
vulnerable_2017 AS (
    SELECT
        zs.state_code,
        AVG(
              COALESCE(z17."employed_wholesale_trade",0)                                  * 0.38423645320197042
            + ( COALESCE(z17."employed_agriculture_forestry_fishing_hunting_mining",0)
              + COALESCE(z17."employed_construction",0) )                                 * 0.48071410777129553
            + COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0)* 0.89455676291236841
            + COALESCE(z17."employed_information",0)                                      * 0.31315240083507306
            + COALESCE(z17."employed_retail_trade",0)                                     * 0.51000000000000000
        ) AS avg_vulnerable_employees_2017
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR" z17
    JOIN zip_state zs
         ON zs.zip_code = z17."geo_id"
    GROUP BY zs.state_code
)

/*───────────────────────────────────────────────────────────
  3. Assemble results and return top‑5 states
───────────────────────────────────────────────────────────*/
SELECT  
    st."state_name"                               AS "state",
    id.avg_income_diff                            AS "avg_income_diff_2015_2018",
    v.avg_vulnerable_employees_2017               AS "avg_vulnerable_employees_2017"
FROM income_diff        id
JOIN vulnerable_2017    v   ON v.state_code = id.state_code
JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."STATES" st
     ON st."state" = id.state_code
ORDER BY id.avg_income_diff DESC NULLS LAST,
         st."state_name"
LIMIT 5;
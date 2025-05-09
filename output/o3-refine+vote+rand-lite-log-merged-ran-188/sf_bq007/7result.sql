WITH vuln AS (
    /* -----------------------------------------------------------
       1. 2017 vulnerable-population score per state
    ----------------------------------------------------------- */
    SELECT
        "geo_id" AS "state_fips",
        (  COALESCE("employed_wholesale_trade",0)      * 0.38423645320197042
         + COALESCE("occupation_natural_resources_construction_maintenance",0)* 0.48071410777129553
         + COALESCE("employed_arts_entertainment_recreation_accommodation_food",0)* 0.89455676291236841
         + COALESCE("employed_information",0)          * 0.31315240083507306
         + COALESCE("employed_retail_trade",0)         * 0.51
         + COALESCE("employed_public_administration",0)* 0.039299298394228743
         + COALESCE("occupation_services",0)           * 0.36555534476489654
         + COALESCE("employed_education_health_social",0)*0.20323178400562944
         + COALESCE("employed_transportation_warehousing_utilities",0)*0.3680506593618087
         + COALESCE("employed_manufacturing",0)        * 0.40618955512572535
        ) AS "vulnerable_population_2017"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."STATE_2017_5YR"
),
inc_change AS (
    /* -----------------------------------------------------------
       2. 2015-to-2018 median-income change per state (ZIP-code avg)
    ----------------------------------------------------------- */
    WITH i15 AS (
        SELECT
            g."state_code",
            AVG( TRY_TO_NUMBER( TO_VARCHAR(z."median_income") ) ) AS "avg_2015"
        FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" z
        JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" g
          ON g."zip_code" = z."geo_id"
        GROUP BY g."state_code"
    ),
    i18 AS (
        SELECT
            g."state_code",
            AVG( TRY_TO_NUMBER( TO_VARCHAR(z."median_income") ) ) AS "avg_2018"
        FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" z
        JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" g
          ON g."zip_code" = z."geo_id"
        GROUP BY g."state_code"
    )
    SELECT
        i18."state_code"                                            AS "state_abbr",
        ( i18."avg_2018" - i15."avg_2015" )                         AS "median_income_change"
    FROM i18
    JOIN i15  ON i18."state_code" = i15."state_code"
)
/* ---------------------------------------------------------------
   3. Combine, sort, and return top-10 states
---------------------------------------------------------------- */
SELECT
    s."state"                                                  AS "state_name",
    ROUND( v."vulnerable_population_2017", 4 )                 AS "vulnerable_population_2017",
    ROUND( ic."median_income_change", 4 )                      AS "median_income_change_2015_2018"
FROM   CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"  s
JOIN   vuln                 v  ON s."fips" = TO_NUMBER( v."state_fips" )
LEFT JOIN inc_change        ic ON ic."state_abbr" = s."postal_code"
ORDER BY v."vulnerable_population_2017" DESC NULLS LAST
LIMIT 10;
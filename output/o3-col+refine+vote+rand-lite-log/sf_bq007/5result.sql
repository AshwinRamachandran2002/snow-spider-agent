/*  Top 10 states by 2017 “vulnerable-population” score
    plus their 2015-to-2018 average median-income change  */

WITH vulnerability AS (
    SELECT 
        sf."postal_code"                                                         AS "state_code",
        0.38423645320197042 * s."employed_wholesale_trade"                                   +
        0.48071410777129553 * s."occupation_natural_resources_construction_maintenance"      +
        0.89455676291236841 * s."employed_arts_entertainment_recreation_accommodation_food"  +
        0.31315240083507306 * s."employed_information"                                       +
        0.51                    * s."employed_retail_trade"                                  +
        0.039299298394228743    * s."employed_public_administration"                         +
        0.36555534476489654     * s."occupation_services"                                    +
        0.20323178400562944     * s."employed_education_health_social"                       +
        0.3680506593618087      * s."employed_transportation_warehousing_utilities"          +
        0.40618955512572535     * s."employed_manufacturing"                    AS "vulnerable_score"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."STATE_2017_5YR"             s
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"                        sf
          ON TO_NUMBER(s."geo_id") = sf."fips"
),
income_2015 AS (
    SELECT 
        b."state_code",
        AVG(z."median_income") AS "avg_2015"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"        z
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"                 b
          ON b."zip_code" = z."geo_id"
    WHERE z."median_income" IS NOT NULL
    GROUP BY b."state_code"
),
income_2018 AS (
    SELECT 
        b."state_code",
        AVG(z."median_income") AS "avg_2018"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"        z
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"                 b
          ON b."zip_code" = z."geo_id"
    WHERE z."median_income" IS NOT NULL
    GROUP BY b."state_code"
),
income_change AS (
    SELECT 
        i15."state_code",
        i18."avg_2018" - i15."avg_2015"  AS "avg_income_change"
    FROM income_2015 i15
    JOIN income_2018 i18
      ON i15."state_code" = i18."state_code"
)
SELECT 
    v."state_code",
    ROUND(v."vulnerable_score", 4)      AS "vulnerable_score",
    ROUND(ic."avg_income_change", 2)    AS "avg_income_change_2015_2018"
FROM vulnerability v
JOIN income_change ic
  ON v."state_code" = ic."state_code"
ORDER BY v."vulnerable_score" DESC NULLS LAST
LIMIT 10;
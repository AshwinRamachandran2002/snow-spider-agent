WITH zip_state AS (     -- map every ZIP to its state (postal) code
    SELECT "zip_code"               AS zip,
           "state_code"             AS state_code
    FROM   CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES
),

/*---------------- 1.  2017 vulnerable-population score ----------------*/
vulnerable_2017 AS (
SELECT 
       zs.state_code,
       SUM(                       -- weighted-sum of employment sectors
             COALESCE(z17."employed_wholesale_trade"                               ,0)*0.38423645320197042 +
             COALESCE(z17."occupation_natural_resources_construction_maintenance"  ,0)*0.48071410777129553 +
             COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0)*0.89455676291236841 +
             COALESCE(z17."employed_information"                                   ,0)*0.31315240083507306 +
             COALESCE(z17."employed_retail_trade"                                  ,0)*0.51 +
             COALESCE(z17."employed_public_administration"                         ,0)*0.039299298394228743 +
             COALESCE(z17."occupation_services"                                    ,0)*0.36555534476489654 +
             COALESCE(z17."employed_education_health_social"                       ,0)*0.20323178400562944 +
             COALESCE(z17."employed_transportation_warehousing_utilities"          ,0)*0.3680506593618087  +
             COALESCE(z17."employed_manufacturing"                                 ,0)*0.40618955512572535
       ) AS total_vulnerable
FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR      z17
JOIN   zip_state                                                      zs
       ON LPAD(z17."geo_id",5,'0') = zs.zip          -- ZIP codes are stored in `geo_id`
GROUP  BY zs.state_code
),

/*---------------- 2.  Average median income, 2015 ----------------*/
income_2015 AS (
SELECT  zs.state_code,
        AVG(
            CASE WHEN z15."median_income" IS NULL OR z15."median_income" < 0
                 THEN NULL
                 ELSE z15."median_income"
            END
        ) AS avg_income_2015
FROM    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR     z15
JOIN    zip_state                                                     zs
        ON LPAD(z15."geo_id",5,'0') = zs.zip
GROUP   BY zs.state_code
),

/*---------------- 3.  Average median income, 2018 ----------------*/
income_2018 AS (
SELECT  zs.state_code,
        AVG(
            CASE WHEN z18."median_income" IS NULL OR z18."median_income" < 0
                 THEN NULL
                 ELSE z18."median_income"
            END
        ) AS avg_income_2018
FROM    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR     z18
JOIN    zip_state                                                     zs
        ON LPAD(z18."geo_id",5,'0') = zs.zip
GROUP   BY zs.state_code
),

/*---------------- 4.  Income change 2015 → 2018 ----------------*/
income_change AS (
SELECT i15.state_code,
       i15.avg_income_2015,
       i18.avg_income_2018,
       i18.avg_income_2018 - i15.avg_income_2015   AS income_change
FROM   income_2015  i15
JOIN   income_2018  i18  ON i15.state_code = i18.state_code
)

/*---------------- 5.  Final result ----------------*/
SELECT  sf."state"                       AS state_name,
        v.state_code                     AS postal_code,
        v.total_vulnerable,
        ic.avg_income_2015,
        ic.avg_income_2018,
        ic.income_change
FROM    vulnerable_2017                                     v
JOIN    income_change                                       ic  ON v.state_code = ic.state_code
JOIN    CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS            sf  ON v.state_code = sf."postal_code"
ORDER BY v.total_vulnerable DESC NULLS LAST
LIMIT 10;
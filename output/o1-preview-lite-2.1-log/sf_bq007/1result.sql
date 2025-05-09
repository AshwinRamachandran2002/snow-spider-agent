WITH vulnerable_states AS (
    SELECT 
        s."geo_id",
        sf."postal_code" AS "state_code",
        ROUND(
            ("employed_wholesale_trade" * 0.3842 +
             "occupation_natural_resources_construction_maintenance" * 0.4807 +
             "employed_arts_entertainment_recreation_accommodation_food" * 0.8946 +
             "employed_information" * 0.3132 +
             "employed_retail_trade" * 0.51 +
             "employed_public_administration" * 0.0393 +
             "employed_other_services_not_public_admin" * 0.3656 +
             "employed_education_health_social" * 0.2032 +
             "employed_transportation_warehousing_utilities" * 0.3681 +
             "employed_manufacturing" * 0.4062
            ), 4
        ) AS "vulnerable_population"
    FROM 
        "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2017_5YR" s
    LEFT JOIN 
        "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS" sf
        ON s."geo_id" = LPAD(sf."fips"::VARCHAR, 2, '0')
),
income2015 AS (
    SELECT 
        z."state_code", 
        ROUND(AVG(c."median_income"), 4) AS "avg_median_income_2015"
    FROM 
        "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES" z
    JOIN 
        "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" c
        ON z."zip_code" = c."geo_id"
    GROUP BY 
        z."state_code"
),
income2018 AS (
    SELECT 
        z."state_code", 
        ROUND(AVG(c."median_income"), 4) AS "avg_median_income_2018"
    FROM 
        "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES" z
    JOIN 
        "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" c
        ON z."zip_code" = c."geo_id"
    GROUP BY 
        z."state_code"
),
income_change AS (
    SELECT 
        i2015."state_code",
        i2015."avg_median_income_2015",
        i2018."avg_median_income_2018",
        ROUND((i2018."avg_median_income_2018" - i2015."avg_median_income_2015"), 4) AS "income_change"
    FROM 
        income2015 i2015
    JOIN 
        income2018 i2018 
        ON i2015."state_code" = i2018."state_code"
)
SELECT 
    vs."state_code",
    vs."vulnerable_population",
    ic."avg_median_income_2015",
    ic."avg_median_income_2018",
    ic."income_change"
FROM 
    vulnerable_states vs
JOIN 
    income_change ic 
    ON vs."state_code" = ic."state_code"
ORDER BY 
    vs."vulnerable_population" DESC NULLS LAST
LIMIT 10;
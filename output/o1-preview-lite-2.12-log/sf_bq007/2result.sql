WITH vulnerable_pop AS (
    SELECT 
        sf."state",
        (
            s."employed_wholesale_trade" * 0.38423645320197042 +
            s."employed_arts_entertainment_recreation_accommodation_food" * 0.89455676291236841 +
            s."employed_information" * 0.31315240083507306 +
            s."employed_retail_trade" * 0.51 +
            s."employed_public_administration" * 0.039299298394228743 +
            s."employed_other_services_not_public_admin" * 0.36555534476489654 +
            s."employed_education_health_social" * 0.20323178400562944 +
            s."employed_transportation_warehousing_utilities" * 0.3680506593618087 +
            s."employed_manufacturing" * 0.40618955512572535 +
            s."occupation_natural_resources_construction_maintenance" * 0.48071410777129553
        ) AS "Vulnerable_Population"
    FROM 
        CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_5YR s
    INNER JOIN
        CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
    ON
        s."geo_id" = LPAD(CAST(sf."fips" AS VARCHAR), 2, '0')
),
median_income_2015 AS (
    SELECT 
        z."state_name",
        AVG(zc15."median_income") AS "median_income_2015"
    FROM 
        CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR zc15
    INNER JOIN
        CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES z
    ON
        zc15."geo_id" = z."zip_code"
    WHERE
        zc15."median_income" IS NOT NULL
    GROUP BY
        z."state_name"
),
median_income_2018 AS (
    SELECT 
        z."state_name",
        AVG(zc18."median_income") AS "median_income_2018"
    FROM 
        CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR zc18
    INNER JOIN
        CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES z
    ON
        zc18."geo_id" = z."zip_code"
    WHERE
        zc18."median_income" IS NOT NULL
    GROUP BY
        z."state_name"
),
median_income_change AS (
    SELECT
        mi15."state_name" AS "State",
        mi18."median_income_2018" - mi15."median_income_2015" AS "Median_Income_Change"
    FROM
        median_income_2015 mi15
    INNER JOIN
        median_income_2018 mi18
    ON 
        mi15."state_name" = mi18."state_name"
)
SELECT
    vp."state" AS "State",
    vp."Vulnerable_Population",
    mi."Median_Income_Change"
FROM
    vulnerable_pop vp
LEFT JOIN
    median_income_change mi
ON
    vp."state" = mi."State"
ORDER BY
    vp."Vulnerable_Population" DESC NULLS LAST
LIMIT 10;
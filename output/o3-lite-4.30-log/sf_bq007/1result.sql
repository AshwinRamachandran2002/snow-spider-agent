WITH vulnerable AS (
    SELECT
        s."geo_id" AS state_fips,
          0.38423645320197042 * s."employed_wholesale_trade"
        + 0.48071410777129553 * s."occupation_natural_resources_construction_maintenance"
        + 0.89455676291236841 * s."employed_arts_entertainment_recreation_accommodation_food"
        + 0.31315240083507306 * s."employed_information"
        + 0.51000000000000000 * s."employed_retail_trade"
        + 0.03929929839422874 * s."employed_public_administration"
        + 0.36555534476489654 * s."occupation_services"
        + 0.20323178400562944 * s."employed_education_health_social"
        + 0.36805065936180870 * s."employed_transportation_warehousing_utilities"
        + 0.40618955512572535 * s."employed_manufacturing"
        AS vulnerable_population_score
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_5YR s
),
income_delta AS (
    SELECT
        b."state_fips_code" AS state_fips,
        AVG(z18."median_income" - z15."median_income") AS avg_median_income_change_2015_2018
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR z18
        ON z15."geo_id" = z18."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES b
        ON z15."geo_id" = b."zip_code"
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
    GROUP BY b."state_fips_code"
),
state_xwalk AS (
    SELECT DISTINCT
        "state_fips_code" AS state_fips,
        "state_name"
    FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES
)
SELECT
    COALESCE(sx."state_name", v.state_fips)                             AS state,
    ROUND(v.vulnerable_population_score, 4)                             AS vulnerable_population_score,
    ROUND(ic.avg_median_income_change_2015_2018, 4)                     AS avg_median_income_change_2015_2018
FROM vulnerable      v
LEFT JOIN state_xwalk sx ON v.state_fips = sx.state_fips
LEFT JOIN income_delta ic ON v.state_fips = ic.state_fips
ORDER BY v.vulnerable_population_score DESC NULLS LAST
LIMIT 10;
WITH vulnerable AS (
    SELECT
        s."geo_id" AS state_fips,
        ROUND(
              0.38423645320197042 * COALESCE(s."employed_wholesale_trade",0) +
              0.48071410777129553 * COALESCE(s."occupation_natural_resources_construction_maintenance",0) +
              0.89455676291236841 * COALESCE(s."employed_arts_entertainment_recreation_accommodation_food",0) +
              0.31315240083507306 * COALESCE(s."employed_information",0) +
              0.51000000000000000 * COALESCE(s."employed_retail_trade",0) +
              0.03929929839422874 * COALESCE(s."employed_public_administration",0) +
              0.36555534476489654 * COALESCE(s."employed_other_services_not_public_admin",0) +
              0.20323178400562944 * COALESCE(s."employed_education_health_social",0) +
              0.36805065936180870 * COALESCE(s."employed_transportation_warehousing_utilities",0) +
              0.40618955512572535 * COALESCE(s."employed_manufacturing",0)
        ,4) AS vulnerable_population_score
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2017_5YR" s
),

income_change AS (
    SELECT
        g."state_fips_code"                                          AS state_fips,
        ROUND(AVG(z18."median_income" - z15."median_income"),4)      AS avg_median_income_change_2015_2018
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" z18
    JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" z15
      ON z18."geo_id" = z15."geo_id"
    JOIN "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES" g
      ON CAST(z18."geo_id" AS TEXT) = g."zip_code"
    WHERE z18."median_income" IS NOT NULL
      AND z15."median_income" IS NOT NULL
    GROUP BY g."state_fips_code"
),

state_lookup AS (
    SELECT
        g."state_fips_code" AS state_fips,
        MAX(g."state_name") AS state
    FROM "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES" g
    GROUP BY g."state_fips_code"
)

SELECT
    sl.state                                                AS state,
    v.vulnerable_population_score                           AS vulnerable_population_score,
    i.avg_median_income_change_2015_2018                    AS avg_median_income_change_2015_2018
FROM vulnerable v
JOIN income_change i  ON v.state_fips = i.state_fips
JOIN state_lookup  sl ON v.state_fips = sl.state_fips
ORDER BY v.vulnerable_population_score DESC NULLS LAST, sl.state
LIMIT 10;
WITH vuln AS (
    SELECT
        "geo_id" AS state_fips,
        (
              COALESCE("employed_wholesale_trade",0)                               * 0.38423645320197042
            + COALESCE("occupation_natural_resources_construction_maintenance",0)  * 0.48071410777129553
            + COALESCE("employed_arts_entertainment_recreation_accommodation_food",0) * 0.89455676291236841
            + COALESCE("employed_information",0)                                   * 0.31315240083507306
            + COALESCE("employed_retail_trade",0)                                  * 0.51
            + COALESCE("employed_public_administration",0)                         * 0.039299298394228743
            + COALESCE("occupation_services",0)                                    * 0.36555534476489654
            + COALESCE("employed_education_health_social",0)                       * 0.20323178400562944
            + COALESCE("employed_transportation_warehousing_utilities",0)          * 0.36805065936180870
            + COALESCE("employed_manufacturing",0)                                 * 0.40618955512572535
        ) AS vulnerable_population_score
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_5YR
),
income_change AS (
    SELECT
        b."state_fips_code"                                     AS state_fips,
        AVG(z18."median_income" - z15."median_income")          AS avg_median_income_change_2015_2018
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR z18
          ON z18."geo_id" = z15."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES b
          ON b."zip_code" = z15."geo_id"
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
    GROUP BY b."state_fips_code"
)
SELECT
    v.state_fips                                                    AS state,
    ROUND(v.vulnerable_population_score, 4)                         AS vulnerable_population_score,
    ROUND(i.avg_median_income_change_2015_2018, 4)                  AS avg_median_income_change_2015_2018
FROM vuln v
LEFT JOIN income_change i
       ON i.state_fips = v.state_fips
ORDER BY vulnerable_population_score DESC NULLS LAST,
         state
LIMIT 10;
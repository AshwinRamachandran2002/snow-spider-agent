WITH vuln_by_state AS (
    /* --- total vulnerable population in 2017 by state (ZIP level weighted sum) --- */
    SELECT
        b."state_name",
        SUM(
              0.38423645320197042 * COALESCE(z17."employed_wholesale_trade",0)
            + 0.48071410777129553 * COALESCE(z17."occupation_natural_resources_construction_maintenance",0)
            + 0.89455676291236841 * COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0)
            + 0.31315240083507306 * COALESCE(z17."employed_information",0)
            + 0.51000000000000000 * COALESCE(z17."employed_retail_trade",0)
            + 0.03929929839422874 * COALESCE(z17."employed_public_administration",0)
            + 0.36555534476489654 * COALESCE(z17."occupation_services",0)
            + 0.20323178400562944 * COALESCE(z17."employed_education_health_social",0)
            + 0.36805065936180870 * COALESCE(z17."employed_transportation_warehousing_utilities",0)
            + 0.40618955512572535 * COALESCE(z17."employed_manufacturing",0)
        ) AS "vulnerable_population"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"            z17
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"                     b
          ON b."zip_code" = z17."geo_id"     -- 5-digit ZIP code identifier
    GROUP BY b."state_name"
),

income_change AS (
    /* --- average ZIP-level median-income change 2015 → 2018, by state --- */
    SELECT
        b."state_name",
        AVG(z18."median_income" - z15."median_income") AS "avg_median_income_change"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"            z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"            z18
          ON z15."geo_id" = z18."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"                     b
          ON b."zip_code" = z15."geo_id"
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
      AND z15."median_income" > 0
      AND z18."median_income" > 0
    GROUP BY b."state_name"
),

combined AS (
    SELECT
        v."state_name",
        v."vulnerable_population",
        i."avg_median_income_change"
    FROM vuln_by_state v
    LEFT JOIN income_change i
           ON v."state_name" = i."state_name"
)

/* --- top 10 states by vulnerable population --- */
SELECT
    "state_name",
    "vulnerable_population",
    "avg_median_income_change"
FROM combined
ORDER BY "vulnerable_population" DESC NULLS LAST
LIMIT 10;
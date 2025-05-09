/* ============================================================
   Top 10 States – Vulnerable Population (2017 ACS 5-YR) & 
   Average ZIP-level Median-Income Change (2015-2018)
   ============================================================ */
WITH boundary AS (                 /* ZIP-to-State look-up  */
    SELECT 
        "zip_code"  AS zip,
        "state_name" AS STATE_NAME   /* un-quoted alias → becomes STATE_NAME */
    FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES
),

/* 1. Vulnerable-Population Score per State (2017) */
vulnerable_state AS (
    SELECT
        b.STATE_NAME,
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
        ) AS vulnerable_population
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR z17
    JOIN boundary b
      ON TRIM(z17."geo_id") = b.zip
    GROUP BY b.STATE_NAME
),

/* 2. Average ZIP-level Median-Income Change (2015 → 2018) */
income_change_state AS (
    SELECT
        b.STATE_NAME,
        AVG( CAST(z18."median_income" AS FLOAT)
            - CAST(z15."median_income" AS FLOAT) ) AS avg_median_income_change
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR z18
      ON TRIM(z15."geo_id") = TRIM(z18."geo_id")
    JOIN boundary b
      ON TRIM(z15."geo_id") = b.zip
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
      AND z15."median_income" > 0
      AND z18."median_income" > 0
    GROUP BY b.STATE_NAME
)

/* 3. Top-10 States */
SELECT 
    v.STATE_NAME,
    v.vulnerable_population,
    i.avg_median_income_change
FROM vulnerable_state v
LEFT JOIN income_change_state i
  ON v.STATE_NAME = i.STATE_NAME
ORDER BY v.vulnerable_population DESC NULLS LAST
LIMIT 10;
WITH /* -----------------------------------------------------------
        1. 2017 vulnerable-population by ZIP
     ----------------------------------------------------------- */
vulnerable_zip AS (
    SELECT
        gb."state_name"                          AS state_name,
        gb."state_code",
        LPAD(TRIM(z17."geo_id"),5,'0')           AS zip_code,
          /* weighted-sum of sector employment counts */
          COALESCE(z17."employed_wholesale_trade",0)                       * 0.38423645320197042 +
          COALESCE(z17."occupation_natural_resources_construction_maintenance",0) * 0.48071410777129553 +
          COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0)* 0.89455676291236841 +
          COALESCE(z17."employed_information",0)                           * 0.31315240083507306 +
          COALESCE(z17."employed_retail_trade",0)                          * 0.51 +
          COALESCE(z17."employed_public_administration",0)                 * 0.039299298394228743 +
          COALESCE(z17."occupation_services",0)                            * 0.36555534476489654 +
          COALESCE(z17."employed_education_health_social",0)               * 0.20323178400562944 +
          COALESCE(z17."employed_transportation_warehousing_utilities",0)  * 0.3680506593618087 +
          COALESCE(z17."employed_manufacturing",0)                         * 0.40618955512572535
        AS vulnerable_population
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  z17
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"           gb
          ON LPAD(TRIM(z17."geo_id"),5,'0') = gb."zip_code"
),

/* -----------------------------------------------------------
        2. Total vulnerable population by state
   ----------------------------------------------------------- */
state_vulnerable AS (
    SELECT
        state_name,
        SUM(vulnerable_population) AS total_vulnerable_population
    FROM   vulnerable_zip
    GROUP  BY state_name
),

/* -----------------------------------------------------------
        3. Median-income change 2015 → 2018 by ZIP
   ----------------------------------------------------------- */
income_change_zip AS (
    SELECT
        gb."state_name"                                         AS state_name,
        TRY_TO_NUMBER(TO_VARCHAR(z18."median_income")) -
        TRY_TO_NUMBER(TO_VARCHAR(z15."median_income"))          AS income_change
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" z18
          ON LPAD(TRIM(z15."geo_id"),5,'0') = LPAD(TRIM(z18."geo_id"),5,'0')
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"       gb
          ON LPAD(TRIM(z15."geo_id"),5,'0') = gb."zip_code"
    WHERE TRY_TO_NUMBER(TO_VARCHAR(z15."median_income")) IS NOT NULL
      AND TRY_TO_NUMBER(TO_VARCHAR(z18."median_income")) IS NOT NULL
),

/* -----------------------------------------------------------
        4. Average income change by state
   ----------------------------------------------------------- */
state_income_change AS (
    SELECT
        state_name,
        AVG(income_change) AS avg_income_change
    FROM   income_change_zip
    GROUP  BY state_name
)

/* -----------------------------------------------------------
        5. Combine & return top-10 states
   ----------------------------------------------------------- */
SELECT
    v.state_name,
    v.total_vulnerable_population,
    i.avg_income_change
FROM   state_vulnerable        v
LEFT   JOIN state_income_change i
       ON v.state_name = i.state_name
ORDER  BY v.total_vulnerable_population DESC NULLS LAST
LIMIT 10;
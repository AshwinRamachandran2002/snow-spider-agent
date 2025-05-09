/* Top-10 states by 2017 “vulnerable population” and their
   average ZIP-level median-income change (2015 → 2018)                 */

WITH state_vulnerability AS (        -- 1) 2017 weighted score
    SELECT
        "geo_id"::INT AS state_fips,
        ( 0.38423645320197042 * "employed_wholesale_trade"
        + 0.48071410777129553 * "occupation_natural_resources_construction_maintenance"
        + 0.89455676291236841 * "employed_arts_entertainment_recreation_accommodation_food"
        + 0.31315240083507306 * "employed_information"
        + 0.51000000000000000 * "employed_retail_trade"
        + 0.03929929839422874 * "employed_public_administration"
        + 0.36555534476489654 * "occupation_services"
        + 0.20323178400562944 * "employed_education_health_social"
        + 0.36805065936180870 * "employed_transportation_warehousing_utilities"
        + 0.40618955512572535 * "employed_manufacturing" ) AS vulnerable_population
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_5YR
),

zip_income_change AS (               -- 2) ZIP-level Δ income
    SELECT
        z15."geo_id"                                                    AS zip_code,
        NULLIF(z18."median_income", -666666666)::FLOAT
      - NULLIF(z15."median_income", -666666666)::FLOAT                  AS income_change
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR z15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR z18
          ON z15."geo_id" = z18."geo_id"
),

zip_with_state AS (                  -- 3) attach state code
    SELECT
        b."state_code"                          AS state_code,
        zic.income_change
    FROM zip_income_change zic
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES b
          ON zic.zip_code = b."zip_code"
    WHERE zic.income_change IS NOT NULL
),

state_income_change AS (             -- 4) average Δ income per state
    SELECT
        state_code,
        AVG(income_change) AS avg_income_change
    FROM zip_with_state
    GROUP BY state_code
),

state_code_map AS (                  -- 5) FIPS ↔ postal code
    SELECT
        "fips"::INT     AS state_fips,
        "postal_code"   AS state_code
    FROM CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS
)

-- 6) final result
SELECT
    sv.state_fips,
    scm.state_code,
    sv.vulnerable_population,
    sic.avg_income_change
FROM state_vulnerability sv
JOIN state_code_map      scm ON sv.state_fips = scm.state_fips
JOIN state_income_change sic ON scm.state_code = sic.state_code
ORDER BY sv.vulnerable_population DESC NULLS LAST
LIMIT 10;
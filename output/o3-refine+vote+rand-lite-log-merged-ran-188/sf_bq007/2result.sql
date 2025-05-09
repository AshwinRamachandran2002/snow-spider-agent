/*--------------------------------------------------------------------
  Top-10 states with the largest 2017 “vulnerable-population” score
  plus the average change in median household income, 2015 → 2018.
----------------------------------------------------------------------*/
WITH vulnerability AS (
    SELECT
        CAST(s."geo_id" AS NUMBER) AS FIPS,
        (
          0.38423645320197042 * s."employed_wholesale_trade"                              +
          0.48071410777129553 * s."occupation_natural_resources_construction_maintenance" +
          0.89455676291236841 * s."employed_arts_entertainment_recreation_accommodation_food" +
          0.31315240083507306 * s."employed_information"                                  +
          0.51000000000000000 * s."employed_retail_trade"                                 +
          0.03929929839422874 * s."employed_public_administration"                        +
          0.36555534476489654 * s."occupation_services"                                   +
          0.20323178400562944 * s."employed_education_health_social"                      +
          0.36805065936180870 * s."employed_transportation_warehousing_utilities"         +
          0.40618955512572535 * s."employed_manufacturing"
        ) AS VULNERABLE_POPULATION_SCORE
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_5YR s
),
/* ---------- 2015 & 2018 ZIP-level median–income averages ---------- */
income_2015 AS (
    SELECT
        g."state_code"                             AS STATE_CODE,
        AVG(CAST(z."median_income" AS FLOAT))      AS AVG_INCOME_2015
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR z
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES g
      ON z."geo_id" = g."zip_code"
    WHERE CAST(z."median_income" AS FLOAT) > 0                       -- drop negative sentinels
    GROUP BY g."state_code"
),
income_2018 AS (
    SELECT
        g."state_code"                             AS STATE_CODE,
        AVG(CAST(z."median_income" AS FLOAT))      AS AVG_INCOME_2018
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR z
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES g
      ON z."geo_id" = g."zip_code"
    WHERE CAST(z."median_income" AS FLOAT) > 0
    GROUP BY g."state_code"
),
income_change AS (
    SELECT
        i18.STATE_CODE,
        i18.AVG_INCOME_2018 - i15.AVG_INCOME_2015  AS MEDIAN_INCOME_CHANGE
    FROM income_2018 i18
    JOIN income_2015 i15
      ON i18.STATE_CODE = i15.STATE_CODE
),
/* ---------- State code ↔ FIPS ↔ state-name cross-walk ---------- */
state_xwalk AS (
    SELECT
        f."fips"          AS FIPS,
        f."postal_code"   AS STATE_CODE,
        f."state"         AS STATE_NAME
    FROM CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS f
)
/* ------------------------------- Result ------------------------------- */
SELECT
    sx.STATE_NAME                         AS STATE,
    sx.STATE_CODE,
    v.VULNERABLE_POPULATION_SCORE,
    ic.MEDIAN_INCOME_CHANGE
FROM   vulnerability v
JOIN   state_xwalk   sx ON v.FIPS       = sx.FIPS
JOIN   income_change ic ON sx.STATE_CODE = ic.STATE_CODE
ORDER  BY v.VULNERABLE_POPULATION_SCORE DESC NULLS LAST
LIMIT 10;
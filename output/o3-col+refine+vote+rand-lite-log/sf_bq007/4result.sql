/* Top-10 states by 2017 ACS “vulnerable population” score
   and their average ZIP-code median-income change (2015 → 2018) */

WITH vulnerable_states AS (      -- 2017 state-level weighted score
    SELECT
        CAST(s."geo_id" AS INTEGER) AS "fips",
        (
              s."employed_wholesale_trade"                             * 0.38423645320197042
            + s."occupation_natural_resources_construction_maintenance" * 0.48071410777129553
            + s."employed_arts_entertainment_recreation_accommodation_food" * 0.89455676291236841
            + s."employed_information"                                  * 0.31315240083507306
            + s."employed_retail_trade"                                 * 0.51
            + s."employed_public_administration"                        * 0.039299298394228743
            + s."occupation_services"                                   * 0.36555534476489654
            + s."employed_education_health_social"                      * 0.20323178400562944
            + s."employed_transportation_warehousing_utilities"         * 0.36805065936180870
            + s."employed_manufacturing"                                * 0.40618955512572535
        ) AS "vulnerable_score"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."STATE_2017_5YR" s
),

zip_income_2015 AS (            -- average ZIP median income, 2015
    SELECT
        g."state_name",
        AVG(IFF(z15."median_income" > 0, z15."median_income", NULL))    AS "avg_2015"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" z15
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"      g
          ON g."zip_code" = z15."geo_id"
    GROUP BY g."state_name"
),

zip_income_2018 AS (            -- average ZIP median income, 2018
    SELECT
        g."state_name",
        AVG(IFF(z18."median_income" > 0, z18."median_income", NULL))    AS "avg_2018"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" z18
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"      g
          ON g."zip_code" = z18."geo_id"
    GROUP BY g."state_name"
),

income_change AS (              -- 2015 → 2018 change per state
    SELECT
        i15."state_name",
        i18."avg_2018" - i15."avg_2015" AS "income_change_2015_2018"
    FROM zip_income_2015 i15
    JOIN zip_income_2018 i18 USING ("state_name")
)

SELECT
    f."state"               AS "state_name",
    v."vulnerable_score",
    i."income_change_2015_2018"
FROM vulnerable_states                          v
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" f  ON f."fips" = v."fips"
JOIN income_change                              i  ON i."state_name" = f."state"
ORDER BY v."vulnerable_score" DESC NULLS LAST
LIMIT 10;
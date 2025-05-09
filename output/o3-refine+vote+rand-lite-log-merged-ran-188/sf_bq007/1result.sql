WITH state_scores AS (
    /* Vulnerable-population score for each state (2017 ACS 5-Year) */
    SELECT
        sf."postal_code"                                                   AS "state_code",
        (   0.38423645320197042  * st."employed_wholesale_trade"
          + 0.48071410777129553  * st."occupation_natural_resources_construction_maintenance"
          + 0.89455676291236841  * st."employed_arts_entertainment_recreation_accommodation_food"
          + 0.31315240083507306  * st."employed_information"
          + 0.51                 * st."employed_retail_trade"
          + 0.039299298394228743 * st."employed_public_administration"
          + 0.36555534476489654  * st."occupation_services"
          + 0.20323178400562944  * st."employed_education_health_social"
          + 0.36805065936180870  * st."employed_transportation_warehousing_utilities"
          + 0.40618955512572535  * st."employed_manufacturing"
        )                                                                 AS "vulnerable_score"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."STATE_2017_5YR" st
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"            sf
          ON TO_NUMBER(st."geo_id") = sf."fips"
),
income_2015 AS (
    /* 2015 average ZIP-level median income per state */
    SELECT
        b."state_code",
        AVG(z."median_income")                                            AS "avg_income_2015"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" z
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"     b
          ON b."zip_code" = TO_CHAR(z."geo_id")
    WHERE z."median_income" IS NOT NULL
    GROUP BY b."state_code"
),
income_2018 AS (
    /* 2018 average ZIP-level median income per state */
    SELECT
        b."state_code",
        AVG(z."median_income")                                            AS "avg_income_2018"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" z
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"     b
          ON b."zip_code" = z."geo_id"
    WHERE z."median_income" IS NOT NULL
    GROUP BY b."state_code"
)
SELECT
    s."state_code",
    s."vulnerable_score",
    (i18."avg_income_2018" - i15."avg_income_2015")                      AS "median_income_change_2018_vs_2015"
FROM state_scores  s
LEFT JOIN income_2015 i15 ON s."state_code" = i15."state_code"
LEFT JOIN income_2018 i18 ON s."state_code" = i18."state_code"
ORDER BY s."vulnerable_score" DESC NULLS LAST
LIMIT 10;
/*======================================================================
  Top-10 states by 2017 “vulnerable population” (weighted employment)
  and their average ZIP-code median–income change (2015 → 2018)
======================================================================*/
WITH weights AS (               /* constant weights for each sector */
    SELECT 0.38423645320197042 AS wt_wholesale ,
           0.48071410777129553 AS wt_nat_res ,
           0.89455676291236841 AS wt_arts ,
           0.31315240083507306 AS wt_info ,
           0.51000000000000000 AS wt_retail ,
           0.03929929839422874 AS wt_public ,
           0.36555534476489654 AS wt_services ,
           0.20323178400562944 AS wt_edu ,
           0.36805065936180870 AS wt_transport ,
           0.40618955512572535 AS wt_manuf
),

/*----------------- 2017 vulnerable-population per state ----------------*/
vulnerable_state AS (
    SELECT
        b."state_code"                                                          AS state_code ,
        SUM(
              COALESCE(z17."employed_wholesale_trade",0)                                  * w.wt_wholesale +
              COALESCE(z17."occupation_natural_resources_construction_maintenance",0)     * w.wt_nat_res  +
              COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0) * w.wt_arts     +
              COALESCE(z17."employed_information",0)                                      * w.wt_info     +
              COALESCE(z17."employed_retail_trade",0)                                     * w.wt_retail   +
              COALESCE(z17."employed_public_administration",0)                            * w.wt_public   +
              COALESCE(z17."occupation_services",0)                                       * w.wt_services +
              COALESCE(z17."employed_education_health_social",0)                          * w.wt_edu      +
              COALESCE(z17."employed_transportation_warehousing_utilities",0)             * w.wt_transport+
              COALESCE(z17."employed_manufacturing",0)                                    * w.wt_manuf
        )                                                               AS vulnerable_population
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR  z17
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES           b
          ON b."zip_code" = z17."geo_id"          -- 5-digit ZIP code
    CROSS JOIN weights w
    GROUP BY b."state_code"
),

/*----------------- average median income per state – 2015 --------------*/
income_2015 AS (
    SELECT
        b."state_code"                               AS state_code ,
        AVG(CAST(z15."median_income" AS FLOAT))      AS avg_income_2015
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR  z15
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES           b
          ON b."zip_code" = z15."geo_id"
    WHERE z15."median_income" IS NOT NULL
      AND z15."median_income" NOT IN (-666666666)
    GROUP BY b."state_code"
),

/*----------------- average median income per state – 2018 --------------*/
income_2018 AS (
    SELECT
        b."state_code"                 AS state_code ,
        AVG(z18."median_income")       AS avg_income_2018
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR  z18
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES           b
          ON b."zip_code" = z18."geo_id"
    WHERE z18."median_income" IS NOT NULL
      AND z18."median_income" NOT IN (-666666666)
    GROUP BY b."state_code"
),

/*----------------- merge scores ---------------------------------------*/
state_scores AS (
    SELECT
        v.state_code ,
        v.vulnerable_population ,
        (i18.avg_income_2018 - i15.avg_income_2015) AS income_change
    FROM vulnerable_state v
    LEFT JOIN income_2015 i15 ON i15.state_code = v.state_code
    LEFT JOIN income_2018 i18 ON i18.state_code = v.state_code
)

/*----------------- final top-10 list ----------------------------------*/
SELECT
    sf."state"                                    AS state_name ,
    s.state_code                                  AS postal_code ,
    ROUND(s.vulnerable_population , 4)            AS vulnerable_population ,
    ROUND(s.income_change        , 4)             AS avg_median_income_change
FROM state_scores s
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS  sf
      ON sf."postal_code" = s.state_code
ORDER BY s.vulnerable_population DESC NULLS LAST
LIMIT 10;
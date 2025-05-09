/* ------------------------------------------------------------
   1.  Calculate a weighted “vulnerable population” for every ZIP
       (2017 ACS 5-Year), then aggregate to the state level.
   2.  Compute each state’s average ZIP-level median household
       income for 2015 and for 2018 and take the difference.
   3.  Return the ten states with the largest vulnerable
       populations together with their 2015-→-2018 income change.
   ------------------------------------------------------------ */
WITH WEIGHTED_VULN AS (     /* ---- 2017 weighted sum per ZIP ---- */
    SELECT
        b."state_name",
        b."state_code",
        /* weighted-sum of all required employment sectors */
          COALESCE(z17."employed_wholesale_trade",0)     * 0.38423645320197042
        + COALESCE(z17."occupation_natural_resources_construction_maintenance",0) * 0.48071410777129553
        + COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0) * 0.89455676291236841
        + COALESCE(z17."employed_information",0)         * 0.31315240083507306
        + COALESCE(z17."employed_retail_trade",0)        * 0.51
        + COALESCE(z17."employed_public_administration",0)* 0.039299298394228743
        + COALESCE(z17."occupation_services",0)          * 0.36555534476489654
        + COALESCE(z17."employed_education_health_social",0) * 0.20323178400562944
        + COALESCE(z17."employed_transportation_warehousing_utilities",0) * 0.3680506593618087
        + COALESCE(z17."employed_manufacturing",0)       * 0.40618955512572535   AS "vulnerable_value"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR"      z17
    JOIN "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES"               b
          ON b."zip_code" = z17."geo_id"
),
STATE_VULN AS (             /* ---- total vulnerable pop per state ---- */
    SELECT
        "state_name",
        "state_code",
        SUM("vulnerable_value") AS "total_vulnerable_population"
    FROM WEIGHTED_VULN
    GROUP BY "state_name","state_code"
),
INCOME_2015 AS (            /* ---- average 2015 median income per state ---- */
    SELECT
        b."state_name",
        b."state_code",
        AVG(
            CASE
                WHEN z15."median_income" IS NULL
                     OR z15."median_income" <= 0
                     OR z15."median_income" = -666666666
                THEN NULL
                ELSE z15."median_income"
            END
        ) AS "avg_income_2015"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR"      z15
    JOIN "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES"               b
          ON b."zip_code" = z15."geo_id"
    GROUP BY b."state_name",b."state_code"
),
INCOME_2018 AS (            /* ---- average 2018 median income per state ---- */
    SELECT
        b."state_name",
        b."state_code",
        AVG(
            CASE
                WHEN z18."median_income" IS NULL
                     OR z18."median_income" <= 0
                     OR z18."median_income" = -666666666
                THEN NULL
                ELSE z18."median_income"
            END
        ) AS "avg_income_2018"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR"      z18
    JOIN "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES"               b
          ON b."zip_code" = z18."geo_id"
    GROUP BY b."state_name",b."state_code"
),
INCOME_CHANGE AS (          /* ---- 2015→2018 change ---- */
    SELECT
        COALESCE(i18."state_name",i15."state_name")   AS "state_name",
        COALESCE(i18."state_code",i15."state_code")   AS "state_code",
        i15."avg_income_2015",
        i18."avg_income_2018",
        i18."avg_income_2018" - i15."avg_income_2015" AS "income_change"
    FROM INCOME_2015 i15
    FULL OUTER JOIN INCOME_2018 i18
      ON i15."state_code" = i18."state_code"
),
FINAL AS (                  /* ---- merge vulnerability & income change ---- */
    SELECT
        v."state_name",
        v."total_vulnerable_population",
        c."income_change"
    FROM STATE_VULN v
    LEFT JOIN INCOME_CHANGE c
           ON v."state_code" = c."state_code"
)
SELECT
    "state_name",
    "total_vulnerable_population",
    "income_change"
FROM FINAL
ORDER BY "total_vulnerable_population" DESC NULLS LAST
LIMIT 10;
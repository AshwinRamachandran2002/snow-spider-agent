/*-----------------------------------------------------------
  1.  Build a ZIP-Code → State lookup from the boundaries table
-----------------------------------------------------------*/
WITH boundary AS (
    SELECT 
        "zip_code"              AS zip,
        "state_name"            AS state_name
    FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES
),

/*-----------------------------------------------------------
  2.  Calculate 2017 “vulnerable population” for every state
-----------------------------------------------------------*/
vulnerable_by_state AS (
    SELECT
        b.state_name,
        /* weighted sum of employment counts (all NULLs → 0) */
        SUM(
              0.38423645320197042  * COALESCE(z17."employed_wholesale_trade",                         0)
            + 0.48071410777129553  * COALESCE(z17."occupation_natural_resources_construction_maintenance", 0)
            + 0.89455676291236841  * COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food", 0)
            + 0.31315240083507306  * COALESCE(z17."employed_information",                              0)
            + 0.51000000000000000  * COALESCE(z17."employed_retail_trade",                            0)
            + 0.03929929839422874  * COALESCE(z17."employed_public_administration",                   0)
            + 0.36555534476489654  * COALESCE(z17."occupation_services",                              0)
            + 0.20323178400562944  * COALESCE(z17."employed_education_health_social",                 0)
            + 0.36805065936180870  * COALESCE(z17."employed_transportation_warehousing_utilities",    0)
            + 0.40618955512572535  * COALESCE(z17."employed_manufacturing",                           0)
        ) AS total_vulnerable_population
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"   z17
    JOIN boundary                                                     b   ON b.zip = z17."geo_id"
    GROUP BY b.state_name
),

/*-----------------------------------------------------------
  3.  Calculate average ZIP-code median-income change,
      2015 → 2018, for every state
-----------------------------------------------------------*/
income_change_state AS (
    /* --- 2015 median income per ZIP -------------------------------- */
    WITH inc15 AS (
        SELECT 
            "geo_id"                               AS zip,
            TO_NUMBER("median_income")             AS med15
        FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"
        WHERE "median_income" IS NOT NULL
              AND TO_NUMBER("median_income")       NOT IN (-666666666)
    ),
    /* --- 2018 median income per ZIP -------------------------------- */
    inc18 AS (
        SELECT 
            "geo_id"                               AS zip,
            TO_NUMBER("median_income")             AS med18
        FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"
        WHERE "median_income" IS NOT NULL
              AND TO_NUMBER("median_income")       NOT IN (-666666666)
    )
    SELECT
        b.state_name,
        AVG(inc18.med18 - inc15.med15) AS avg_income_change
    FROM inc15
    JOIN inc18      ON inc15.zip = inc18.zip                 /* keep ZIPs present in both years */
    JOIN boundary   b  ON b.zip      = inc15.zip
    GROUP BY b.state_name
),

/*-----------------------------------------------------------
  4.  Combine both metrics
-----------------------------------------------------------*/
combined AS (
    SELECT
        v.state_name,
        v.total_vulnerable_population,
        i.avg_income_change
    FROM   vulnerable_by_state v
    LEFT JOIN income_change_state i
           ON v.state_name = i.state_name
)

/*-----------------------------------------------------------
  5.  Return the TOP-10 states by vulnerable population
-----------------------------------------------------------*/
SELECT
    state_name,
    total_vulnerable_population,
    avg_income_change
FROM combined
ORDER BY total_vulnerable_population DESC NULLS LAST
LIMIT 10;
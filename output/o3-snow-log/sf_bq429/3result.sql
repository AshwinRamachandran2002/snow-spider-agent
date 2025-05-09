/* Top-5 states: greatest average ZIP-level median-income change (2015→2018)
   and their average number of “vulnerable” employees (2017)                */

WITH income_diff AS (   -- ZIP-level income change -------------------------
    SELECT
        CAST(LEFT(a."geo_id", 2) AS NUMBER)                        AS state_fips,
        (b."median_income" - a."median_income")                    AS income_diff
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  a
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  b
          ON a."geo_id" = b."geo_id"
    WHERE a."median_income" IS NOT NULL
      AND b."median_income" IS NOT NULL
),
state_income AS (        -- State-average income change --------------------
    SELECT
        state_fips,
        AVG(income_diff) AS avg_zip_income_diff_2015_2018
    FROM income_diff
    GROUP BY state_fips
),
vulnerable_zip AS (      -- ZIP-level vulnerable-employee count (2017) -----
    SELECT
        CAST(LEFT("geo_id", 2) AS NUMBER)                                      AS state_fips,
        ("employed_wholesale_trade"  * 0.38423645320197042 +
         "employed_construction"     * 0.48071410777129553 +
         "employed_arts_entertainment_recreation_accommodation_food"
                                   * 0.89455676291236841 +
         "employed_information"      * 0.31315240083507306 +
         "employed_retail_trade"     * 0.51)                                   AS vulnerable_employees
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
),
state_vulnerable AS (    -- State-average vulnerable employees -------------
    SELECT
        state_fips,
        AVG(vulnerable_employees) AS avg_vulnerable_employees_2017
    FROM vulnerable_zip
    GROUP BY state_fips
)

SELECT
    f."state",
    i.avg_zip_income_diff_2015_2018,
    v.avg_vulnerable_employees_2017
FROM   state_income     i
JOIN   state_vulnerable v  ON i.state_fips = v.state_fips
JOIN   CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"  f
       ON i.state_fips = f."fips"
ORDER  BY i.avg_zip_income_diff_2015_2018 DESC NULLS LAST
LIMIT 5;
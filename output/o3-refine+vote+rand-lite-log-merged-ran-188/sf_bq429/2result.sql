WITH zip_2015 AS (        -- 2015 ZIP-level median income (convert text / numeric to DECIMAL)
    SELECT
        "geo_id",
        TRY_TO_DECIMAL("median_income"::VARCHAR)  AS "median_income_2015"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"
    WHERE TRY_TO_DECIMAL("median_income"::VARCHAR) > 0          -- valid, positive values
),
zip_2018 AS (             -- 2018 ZIP-level median income (same conversion)
    SELECT
        "geo_id",
        TRY_TO_DECIMAL("median_income"::VARCHAR)  AS "median_income_2018"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"
    WHERE TRY_TO_DECIMAL("median_income"::VARCHAR) > 0          -- valid, positive values
),
zip_diffs AS (            -- change in median income for ZIPs present in both years
    SELECT
        z15."geo_id",
        z18."median_income_2018" - z15."median_income_2015"  AS "median_diff"
    FROM zip_2015 z15
    JOIN zip_2018 z18
          ON z15."geo_id" = z18."geo_id"
),
state_income_change AS (  -- average ZIP-level change per state (first two ZIP digits)
    SELECT
        SUBSTR("geo_id", 1, 2)        AS "state_fips_prefix",
        AVG("median_diff")            AS "avg_median_diff_2015_2018"
    FROM zip_diffs
    GROUP BY 1
    ORDER BY "avg_median_diff_2015_2018" DESC
    LIMIT 5                           -- top-5 states with largest positive change
),
zip_vulnerable_2017 AS (   -- weighted vulnerable employment count, 2017
    SELECT
        "geo_id",
          0.38423645320197042 * COALESCE("employed_wholesale_trade", 0)
        + 0.48071410777129553 * COALESCE("employed_construction", 0)
        + 0.89455676291236841 * COALESCE("employed_arts_entertainment_recreation_accommodation_food", 0)
        + 0.31315240083507306 * COALESCE("employed_information", 0)
        + 0.51                 * COALESCE("employed_retail_trade", 0) AS "vulnerable_emp"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
),
state_vulnerable_2017 AS ( -- average vulnerable employment per state
    SELECT
        SUBSTR("geo_id", 1, 2) AS "state_fips_prefix",
        AVG("vulnerable_emp")  AS "avg_vulnerable_emp_2017"
    FROM zip_vulnerable_2017
    GROUP BY 1
)
-- FINAL: top-5 income-gain states with their average 2017 vulnerable employment
SELECT
    s."state_fips_prefix",
    s."avg_median_diff_2015_2018",
    v."avg_vulnerable_emp_2017"
FROM state_income_change   s
LEFT JOIN state_vulnerable_2017 v
       ON s."state_fips_prefix" = v."state_fips_prefix"
ORDER BY s."avg_median_diff_2015_2018" DESC;
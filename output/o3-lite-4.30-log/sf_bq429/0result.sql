WITH income_diff AS (
    /* 2015‑to‑2018 change in median household income for each ZIP code */
    SELECT
        a."geo_id",
        b."median_income" - a."median_income" AS "income_diff"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR a
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR b
          ON a."geo_id" = b."geo_id"
    WHERE a."median_income" IS NOT NULL
      AND b."median_income" IS NOT NULL
),
vulnerable_emp AS (
    /* 2017 weighted count of workers in vulnerable industries for each ZIP code */
    SELECT
        z."geo_id",
          0.38423645320197042 * COALESCE(z."employed_wholesale_trade",0) +
          0.48071410777129553 * ( COALESCE(z."employed_construction",0)
                                + COALESCE(z."employed_agriculture_forestry_fishing_hunting_mining",0) ) +
          0.89455676291236841 * COALESCE(z."employed_arts_entertainment_recreation_accommodation_food",0) +
          0.31315240083507306 * COALESCE(z."employed_information",0) +
          0.51                 * COALESCE(z."employed_retail_trade",0)    AS "weighted_vulnerable_emp"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR z
)
SELECT
    g."state_name"                                                   AS state,
    ROUND(AVG(id."income_diff"), 4)                                  AS avg_diff_median_income_2015_2018,
    ROUND(AVG(ve."weighted_vulnerable_emp"), 4)                      AS avg_vulnerable_employees_2017
FROM income_diff      id
JOIN vulnerable_emp   ve  ON id."geo_id" = ve."geo_id"
JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES g
     ON LPAD(id."geo_id", 5, '0') = g."zip_code"
GROUP BY g."state_name"
ORDER BY avg_diff_median_income_2015_2018 DESC NULLS LAST,
         g."state_name"
LIMIT 5;
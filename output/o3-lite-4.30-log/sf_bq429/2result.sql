WITH income_change AS (
    SELECT
        t15."geo_id",
        (t18."median_income" - t15."median_income") AS "income_delta"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  t15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  t18
      ON t15."geo_id" = t18."geo_id"
    WHERE t15."median_income" IS NOT NULL
      AND t18."median_income" IS NOT NULL
),
vulnerable_emp AS (
    SELECT
        "geo_id",
        (
            COALESCE("employed_wholesale_trade",0) +
            COALESCE("employed_construction",0) +
            COALESCE("employed_agriculture_forestry_fishing_hunting_mining",0) +
            COALESCE("employed_arts_entertainment_recreation_accommodation_food",0) +
            COALESCE("employed_information",0) +
            COALESCE("employed_retail_trade",0)
        ) / 5.0 AS "avg_vulnerable_employees_2017"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
)
SELECT
    g."state_name"                                                        AS state,
    ROUND(AVG(ic."income_delta"), 4)                                       AS avg_diff_median_income_2015_2018,
    ROUND(AVG(ve."avg_vulnerable_employees_2017"), 4)                      AS avg_vulnerable_employees_2017
FROM income_change        ic
JOIN vulnerable_emp       ve ON ic."geo_id" = ve."geo_id"
JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" g
     ON g."zip_code" = ic."geo_id"
GROUP BY g."state_name"
ORDER BY avg_diff_median_income_2015_2018 DESC NULLS LAST, state
LIMIT 5;
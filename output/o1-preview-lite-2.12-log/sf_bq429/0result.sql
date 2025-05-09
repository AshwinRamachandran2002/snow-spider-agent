SELECT
    zg."state_name" AS "State",
    AVG(z2018."median_income" - z2015."median_income") AS "Average_Median_Income_Difference",
    AVG(
        COALESCE(z2017."employed_wholesale_trade", 0) * 0.38423645320197042 +
        (
            COALESCE(z2017."employed_construction", 0) +
            COALESCE(z2017."employed_agriculture_forestry_fishing_hunting_mining", 0)
        ) * 0.48071410777129553 +
        COALESCE(z2017."employed_arts_entertainment_recreation_accommodation_food", 0) * 0.89455676291236841 +
        COALESCE(z2017."employed_information", 0) * 0.31315240083507306 +
        COALESCE(z2017."employed_retail_trade", 0) * 0.51
    ) AS "Average_Vulnerable_Employees"
FROM
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" AS z2015
JOIN
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" AS z2018
    ON z2015."geo_id" = z2018."geo_id"
JOIN
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR" AS z2017
    ON z2015."geo_id" = z2017."geo_id"
JOIN
    "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES" AS zg
    ON z2015."geo_id" = zg."zip_code"
WHERE
    z2015."median_income" IS NOT NULL
    AND z2018."median_income" IS NOT NULL
    AND zg."state_name" IS NOT NULL
GROUP BY
    zg."state_name"
ORDER BY
    "Average_Median_Income_Difference" DESC NULLS LAST
LIMIT 5;
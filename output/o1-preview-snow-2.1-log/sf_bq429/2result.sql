SELECT
    s."state_name" AS "State",
    ROUND((s2018."median_income" - s2015."median_income"), 4) AS "Median_Income_Difference",
    ROUND((
        s2017."employed_wholesale_trade" * 0.38423645320197042 +
        (s2017."employed_construction" + s2017."employed_agriculture_forestry_fishing_hunting_mining") * 0.48071410777129553 +
        s2017."employed_arts_entertainment_recreation_accommodation_food" * 0.89455676291236841 +
        s2017."employed_information" * 0.31315240083507306 +
        s2017."employed_retail_trade" * 0.51
    ) / 5, 4) AS "Average_Vulnerable_Employees"
FROM
    "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."STATES" s
JOIN
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2015_5YR" s2015
        ON s."state_fips_code" = s2015."geo_id"
JOIN
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2018_5YR" s2018
        ON s2015."geo_id" = s2018."geo_id"
JOIN
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2017_5YR" s2017
        ON s2015."geo_id" = s2017."geo_id"
ORDER BY
    "Median_Income_Difference" DESC NULLS LAST
LIMIT 5;
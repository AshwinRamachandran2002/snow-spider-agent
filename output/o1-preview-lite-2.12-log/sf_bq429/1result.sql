SELECT
    g."state_name" AS "State",
    AVG(b."median_income" - a."median_income") AS "Average_Median_Income_Difference",
    AVG(
        (e."employed_wholesale_trade" * 0.38423645320197042) +
        ((e."employed_agriculture_forestry_fishing_hunting_mining" + e."employed_construction") * 0.48071410777129553) +
        (e."employed_arts_entertainment_recreation_accommodation_food" * 0.89455676291236841) +
        (e."employed_information" * 0.31315240083507306) +
        (e."employed_retail_trade" * 0.51)
    ) AS "Average_Vulnerable_Employees"
FROM
    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" AS a
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" AS b
        ON a."geo_id" = b."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR" AS e
        ON a."geo_id" = e."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" AS g
        ON a."geo_id" = g."zip_code"
GROUP BY
    g."state_name"
ORDER BY
    "Average_Median_Income_Difference" DESC NULLS LAST
LIMIT 5;
SELECT inc."state" AS "State",
       ROUND(inc."average_median_income_difference", 4) AS "Average_Median_Income_Difference",
       ROUND(emp."Average_Vulnerable_Employees", 4) AS "Average_Vulnerable_Employees"
FROM
(
    SELECT s."state",
           AVG(b."median_income" - a."median_income") AS "average_median_income_difference"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" AS a
    INNER JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" AS b
        ON a."geo_id" = b."geo_id"
    INNER JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" AS z
        ON LPAD(a."geo_id", 5, '0') = z."zip_code"
    INNER JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" AS s
        ON z."state_fips_code" = s."fips"
    WHERE a."median_income" IS NOT NULL AND b."median_income" IS NOT NULL
    GROUP BY s."state"
) AS inc
INNER JOIN
(
    SELECT s."state",
           AVG(
               e."employed_wholesale_trade" * 0.38423645320197042
               + (e."employed_construction" + e."employed_agriculture_forestry_fishing_hunting_mining") * 0.48071410777129553
               + e."employed_arts_entertainment_recreation_accommodation_food" * 0.89455676291236841
               + e."employed_information" * 0.31315240083507306
               + e."employed_retail_trade" * 0.51
           ) AS "Average_Vulnerable_Employees"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR" AS e
    INNER JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES" AS z
        ON LPAD(e."geo_id", 5, '0') = z."zip_code"
    INNER JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" AS s
        ON z."state_fips_code" = s."fips"
    GROUP BY s."state"
) AS emp
ON inc."state" = emp."state"
ORDER BY inc."average_median_income_difference" DESC NULLS LAST
LIMIT 5;
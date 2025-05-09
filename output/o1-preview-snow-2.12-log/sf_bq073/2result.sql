WITH income_decreased_zips AS (
    SELECT
        z2017."geo_id",
        z2018."median_income" - z2015."median_income" AS "income_difference",
        z2017."employed_wholesale_trade",
        z2017."employed_manufacturing"
    FROM
        "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" AS z2015
        JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" AS z2018
            ON z2015."geo_id" = z2018."geo_id"
        JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR" AS z2017
            ON z2015."geo_id" = z2017."geo_id"
    WHERE
        (z2018."median_income" - z2015."median_income") < 0
)

SELECT
    zbound."state_name" AS "State_Name",
    ROUND(SUM(income_decreased_zips."employed_wholesale_trade" * 0.38), 4) AS "Vulnerable_Wholesale_Trade_Workers",
    ROUND(SUM(income_decreased_zips."employed_manufacturing" * 0.41), 4) AS "Vulnerable_Manufacturing_Workers",
    ROUND(SUM(income_decreased_zips."employed_wholesale_trade" * 0.38 + income_decreased_zips."employed_manufacturing" * 0.41), 4) AS "Total_Vulnerable_Workers"
FROM
    income_decreased_zips
    JOIN "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES" AS zbound
        ON income_decreased_zips."geo_id" = zbound."zip_code"
GROUP BY
    zbound."state_name"
ORDER BY
    "Total_Vulnerable_Workers" DESC NULLS LAST;
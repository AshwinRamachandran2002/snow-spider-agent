WITH unemployment_2015 AS (
    SELECT "geo_id" AS "county_id",
           "unemployed_pop" AS "unemployed_2015",
           "civilian_labor_force" AS "labor_force_2015",
           ("unemployed_pop" / "civilian_labor_force") * 100 AS "unemployment_rate_2015"
    FROM SDOH.CENSUS_BUREAU_ACS.COUNTY_2015_5YR
    WHERE "civilian_labor_force" > 0 AND "unemployed_pop" IS NOT NULL
),
unemployment_2018 AS (
    SELECT "geo_id" AS "county_id",
           "unemployed_pop" AS "unemployed_2018",
           "civilian_labor_force" AS "labor_force_2018",
           ("unemployed_pop" / "civilian_labor_force") * 100 AS "unemployment_rate_2018"
    FROM SDOH.CENSUS_BUREAU_ACS.COUNTY_2018_5YR
    WHERE "civilian_labor_force" > 0 AND "unemployed_pop" IS NOT NULL
),
enrollment_2015 AS (
    SELECT "FIPS" AS "county_id", "Public_Total" AS "enrollment_2015"
    FROM SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT.DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM
    WHERE "Date" = '2015-12-01'
),
enrollment_2018 AS (
    SELECT "FIPS" AS "county_id", "Public_Total" AS "enrollment_2018"
    FROM SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT.DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM
    WHERE "Date" = '2018-12-01'
),
unemployment AS (
    SELECT u2015."county_id",
           u2015."unemployment_rate_2015",
           u2018."unemployment_rate_2018"
    FROM unemployment_2015 u2015
    INNER JOIN unemployment_2018 u2018 ON u2015."county_id" = u2018."county_id"
),
enrollment AS (
    SELECT e2015."county_id", e2015."enrollment_2015", e2018."enrollment_2018"
    FROM enrollment_2015 e2015
    INNER JOIN enrollment_2018 e2018 ON e2015."county_id" = e2018."county_id"
),
combined_data AS (
    SELECT u."county_id",
           ROUND(u."unemployment_rate_2015", 4) AS "unemployment_rate_2015",
           ROUND(u."unemployment_rate_2018", 4) AS "unemployment_rate_2018",
           e."enrollment_2015",
           e."enrollment_2018"
    FROM unemployment u
    INNER JOIN enrollment e ON u."county_id" = e."county_id"
)
SELECT COUNT(*) AS "Number_of_Counties"
FROM combined_data
WHERE "unemployment_rate_2018" > "unemployment_rate_2015"
  AND "enrollment_2018" < "enrollment_2015";
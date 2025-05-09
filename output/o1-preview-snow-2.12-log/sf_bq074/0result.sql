WITH unemployment_2015 AS (
  SELECT
    LPAD("geo_id",5,'0') AS "geo_id",
    ROUND(CAST("unemployed_pop" AS FLOAT) / NULLIF("civilian_labor_force", 0) * 100, 4) AS unemployment_rate_2015
  FROM
    SDOH.CENSUS_BUREAU_ACS.COUNTY_2015_5YR
),
unemployment_2018 AS (
  SELECT
    LPAD("geo_id",5,'0') AS "geo_id",
    ROUND(CAST("unemployed_pop" AS FLOAT) / NULLIF("civilian_labor_force", 0) * 100, 4) AS unemployment_rate_2018
  FROM
    SDOH.CENSUS_BUREAU_ACS.COUNTY_2018_5YR
),
unemployment_change AS (
  SELECT
    u15."geo_id",
    u15.unemployment_rate_2015,
    u18.unemployment_rate_2018
  FROM
    unemployment_2015 u15
    JOIN unemployment_2018 u18 ON u15."geo_id" = u18."geo_id"
  WHERE
    u18.unemployment_rate_2018 > u15.unemployment_rate_2015
),
enrollment_2015 AS (
  SELECT
    LPAD("FIPS",5,'0') AS "FIPS",
    SUM("Public_Total") AS enrollment_2015
  FROM
    SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT.DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM
  WHERE
    "Date" = '2015-12-01'
  GROUP BY
    LPAD("FIPS",5,'0')
),
enrollment_2018 AS (
  SELECT
    LPAD("FIPS",5,'0') AS "FIPS",
    SUM("Public_Total") AS enrollment_2018
  FROM
    SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT.DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM
  WHERE
    "Date" = '2018-12-01'
  GROUP BY
    LPAD("FIPS",5,'0')
),
enrollment_change AS (
  SELECT
    e15."FIPS",
    e15.enrollment_2015,
    e18.enrollment_2018
  FROM
    enrollment_2015 e15
    JOIN enrollment_2018 e18 ON e15."FIPS" = e18."FIPS"
  WHERE
    e18.enrollment_2018 < e15.enrollment_2015
)

SELECT
  COUNT(DISTINCT u."geo_id") AS "Number_of_Counties"
FROM
  unemployment_change u
  JOIN enrollment_change e ON u."geo_id" = e."FIPS";
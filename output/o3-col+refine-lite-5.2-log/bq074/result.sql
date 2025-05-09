WITH
-- Unemployment counts
unemp_2015 AS (
  SELECT
    geo_id,
    unemployed_pop AS u2015
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
),
unemp_2018 AS (
  SELECT
    geo_id,
    unemployed_pop AS u2018
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),

-- Dual–eligible enrollment counts (end of calendar years)
duals_2015 AS (
  SELECT
    FIPS AS geo_id,
    Public_Total AS d2015
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2015-12-01'
),
duals_2018 AS (
  SELECT
    FIPS AS geo_id,
    Public_Total AS d2018
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2018-12-01'
)

SELECT
  COUNTIF(u2018 > u2015 AND d2018 < d2015) AS cnt_counties_meeting_both_criteria
FROM unemp_2015
JOIN unemp_2018 USING (geo_id)
JOIN duals_2015 USING (geo_id)
JOIN duals_2018 USING (geo_id);
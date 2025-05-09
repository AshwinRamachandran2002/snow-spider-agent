WITH
acs15 AS (
  SELECT geo_id, unemployed_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
),
acs18 AS (
  SELECT geo_id, unemployed_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),
unemp_increase AS (
  SELECT a15.geo_id
  FROM acs15 AS a15
  JOIN acs18 AS a18
  ON a15.geo_id = a18.geo_id
  WHERE a15.unemployed_pop IS NOT NULL
    AND a18.unemployed_pop IS NOT NULL
    AND a18.unemployed_pop > a15.unemployed_pop
),
cms15 AS (
  SELECT FIPS, Public_Total
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2015-12-01'
),
cms18 AS (
  SELECT FIPS, Public_Total
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2018-12-01'
),
duals_decrease AS (
  SELECT c15.FIPS
  FROM cms15 AS c15
  JOIN cms18 AS c18
  ON c15.FIPS = c18.FIPS
  WHERE c15.Public_Total IS NOT NULL
    AND c18.Public_Total IS NOT NULL
    AND c18.Public_Total < c15.Public_Total
)
SELECT
  CAST(COUNT(*) AS NUMERIC) + 0.0000 AS counties_with_unemployment_increase_and_dual_eligible_decrease
FROM unemp_increase
JOIN duals_decrease
ON unemp_increase.geo_id = duals_decrease.FIPS;
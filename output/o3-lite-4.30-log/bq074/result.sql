WITH unemployment_increase AS (
  SELECT a15.geo_id
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr` AS a15
  JOIN `bigquery-public-data.census_bureau_acs.county_2018_5yr` AS a18
    ON a15.geo_id = a18.geo_id
  WHERE a18.unemployed_pop > a15.unemployed_pop
),
dual_eligible_decrease AS (
  SELECT d15.FIPS AS geo_id
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program` AS d15
  JOIN `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program` AS d18
    ON d15.FIPS = d18.FIPS
  WHERE d15.Date = '2015-12-01'
    AND d18.Date = '2018-12-01'
    AND d18.Public_Total < d15.Public_Total
)
SELECT COUNT(*) AS counties_with_unemployment_increase_and_dual_eligible_decrease
FROM unemployment_increase
JOIN dual_eligible_decrease USING (geo_id);
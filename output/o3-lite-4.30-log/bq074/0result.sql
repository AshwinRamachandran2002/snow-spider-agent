SELECT
  COUNT(*) AS counties_with_unemployment_increase_and_dual_eligible_decrease
FROM (
  SELECT u.geo_id
  FROM (
    SELECT
      a.geo_id,
      a.unemployed_pop AS unemp15,
      b.unemployed_pop AS unemp18
    FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr` AS a
    JOIN `bigquery-public-data.census_bureau_acs.county_2018_5yr`  AS b
      ON a.geo_id = b.geo_id
    WHERE a.unemployed_pop IS NOT NULL
      AND b.unemployed_pop IS NOT NULL
  ) AS u
  JOIN (
    SELECT
      d15.FIPS,
      d15.dual15,
      d18.dual18
    FROM (
      SELECT FIPS, Public_Total AS dual15
      FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
      WHERE `Date` = '2015-12-01'
    ) AS d15
    JOIN (
      SELECT FIPS, Public_Total AS dual18
      FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
      WHERE `Date` = '2018-12-01'
    ) AS d18
      ON d15.FIPS = d18.FIPS
  ) AS d
    ON u.geo_id = d.FIPS
  WHERE u.unemp18 > u.unemp15
    AND d.dual18 < d.dual15
);
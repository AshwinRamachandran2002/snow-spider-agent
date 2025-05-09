SELECT
  COUNT(*) AS Number_of_Counties
FROM (
  SELECT
    unemployment.FIPS
  FROM
    (
      SELECT
        LPAD(CAST(a.geo_id AS STRING),5,'0') AS FIPS,
        (a.unemployed_pop / a.pop_in_labor_force) AS unemployment_rate_2015,
        (b.unemployed_pop / b.pop_in_labor_force) AS unemployment_rate_2018
      FROM
        `bigquery-public-data.census_bureau_acs.county_2015_5yr` AS a
      JOIN
        `bigquery-public-data.census_bureau_acs.county_2018_5yr` AS b
      ON
        a.geo_id = b.geo_id
      WHERE
        a.pop_in_labor_force > 0
        AND b.pop_in_labor_force > 0
        AND (b.unemployed_pop / b.pop_in_labor_force) > (a.unemployed_pop / a.pop_in_labor_force)
    ) AS unemployment
  INNER JOIN
    (
      SELECT
        a.FIPS
      FROM
        `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program` AS a
      JOIN
        `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program` AS b
      ON
        a.FIPS = b.FIPS
      WHERE
        a.Date = '2015-12-01'
        AND b.Date = '2018-12-01'
        AND b.Public_Total < a.Public_Total
    ) AS enrollment
  ON
    unemployment.FIPS = enrollment.FIPS
);
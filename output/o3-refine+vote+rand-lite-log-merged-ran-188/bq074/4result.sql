-- number of counties with 2015‑18 unemployment increase (ACS 5‑yr)
-- AND a decrease in dual‑eligible enrollment between
-- 2015‑12‑01 and 2018‑12‑01
WITH unemployment AS (
  SELECT
    c15.geo_id                                   AS fips,
    SAFE_CAST(c15.unemployed_pop AS FLOAT64)     AS unemployed_2015,
    SAFE_CAST(c18.unemployed_pop AS FLOAT64)     AS unemployed_2018
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr` AS c15
  JOIN `bigquery-public-data.census_bureau_acs.county_2018_5yr` AS c18
    ON c15.geo_id = c18.geo_id
),
unemployment_increase AS (
  SELECT fips
  FROM unemployment
  WHERE unemployed_2018 > unemployed_2015
),

dual2015 AS (
  SELECT
    FIPS AS fips,
    Public_Total AS dual_2015
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2015-12-01'
),
dual2018 AS (
  SELECT
    FIPS AS fips,
    Public_Total AS dual_2018
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2018-12-01'
),
dual_decrease AS (
  SELECT d15.fips
  FROM dual2015 d15
  JOIN dual2018 d18
    USING (fips)
  WHERE d18.dual_2018 < d15.dual_2015
)

SELECT COUNT(*) AS counties_meeting_both_conditions
FROM unemployment_increase
JOIN dual_decrease USING (fips);
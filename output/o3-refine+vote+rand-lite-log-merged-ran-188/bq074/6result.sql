WITH
-- Unemployment counts from the 2015 and 2018 5‑year ACS county files
unemp_2015 AS (
  SELECT
    geo_id AS fips,
    CAST(unemployed_pop AS INT64) AS unemployed_2015
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
),
unemp_2018 AS (
  SELECT
    geo_id AS fips,
    CAST(unemployed_pop AS INT64) AS unemployed_2018
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),

-- Dual‑eligible enrollment on 1 Dec 2015
dual_2015 AS (
  SELECT
    LPAD(FIPS, 5, '0') AS fips,
    SUM(Public_Total) AS dual_enroll_2015
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2015-12-01'
  GROUP BY fips
),

-- Dual‑eligible enrollment on 1 Dec 2018
dual_2018 AS (
  SELECT
    LPAD(FIPS, 5, '0') AS fips,
    SUM(Public_Total) AS dual_enroll_2018
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2018-12-01'
  GROUP BY fips
),

-- Combine all four measures by county
combined AS (
  SELECT
    u15.fips,
    u15.unemployed_2015,
    u18.unemployed_2018,
    d15.dual_enroll_2015,
    d18.dual_enroll_2018
  FROM unemp_2015 u15
  JOIN unemp_2018 u18 USING (fips)
  JOIN dual_2015 d15 USING (fips)
  JOIN dual_2018 d18 USING (fips)
)

-- Count counties meeting both criteria
SELECT
  COUNT(*) AS counties_meeting_conditions
FROM combined
WHERE unemployed_2018 > unemployed_2015        -- unemployment increased
  AND dual_enroll_2018 < dual_enroll_2015;     -- dual‑eligible enrollment decreased
WITH
-- 5‑year ACS county–level unemployment counts
unemp_2015 AS (
  SELECT
    CAST(geo_id AS STRING)                    AS fips,
    CAST(unemployed_pop AS FLOAT64)           AS unemployed_2015
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  WHERE unemployed_pop IS NOT NULL
),
unemp_2018 AS (
  SELECT
    CAST(geo_id AS STRING)                    AS fips,
    CAST(unemployed_pop AS FLOAT64)           AS unemployed_2018
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  WHERE unemployed_pop IS NOT NULL
),
unemployment AS (
  SELECT
    u15.fips,
    u15.unemployed_2015,
    u18.unemployed_2018
  FROM unemp_2015 u15
  JOIN unemp_2018 u18 USING (fips)
),

-- Dual‑eligible enrollee counts (aggregate to county level)
dual_2015 AS (
  SELECT
    FIPS AS fips,
    SUM(Public_Total) AS dual_2015
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2015-12-01'
  GROUP BY fips
),
dual_2018 AS (
  SELECT
    FIPS AS fips,
    SUM(Public_Total) AS dual_2018
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2018-12-01'
  GROUP BY fips
),
dual_enrollment AS (
  SELECT
    d15.fips,
    d15.dual_2015,
    d18.dual_2018
  FROM dual_2015 d15
  JOIN dual_2018 d18 USING (fips)
),

-- Counties meeting both criteria
eligible_counties AS (
  SELECT
    u.fips
  FROM unemployment u
  JOIN dual_enrollment d USING (fips)
  WHERE u.unemployed_2018 > u.unemployed_2015      -- unemployment increased
    AND d.dual_2018 < d.dual_2015                  -- dual‑eligible enrollment decreased
)

SELECT COUNT(DISTINCT fips) AS county_count
FROM eligible_counties;
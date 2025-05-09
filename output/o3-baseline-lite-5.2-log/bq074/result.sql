WITH
-- 5‑year ACS county‑level unemployment counts
unemp_2015 AS (
  SELECT
    CAST(geo_id AS STRING)                     AS fips,
    CAST(unemployed_pop AS FLOAT64)            AS unemployed_2015
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
),
unemp_2018 AS (
  SELECT
    CAST(geo_id AS STRING)                     AS fips,
    CAST(unemployed_pop AS FLOAT64)            AS unemployed_2018
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),

-- counties whose unemployment rose from 2015‑5yr → 2018‑5yr
unemp_increase AS (
  SELECT u15.fips
  FROM unemp_2015 u15
  JOIN unemp_2018 u18 USING (fips)
  WHERE u18.unemployed_2018 > u15.unemployed_2015
),

-- dual‑eligible enrollment (sum over all program rows) on the two target dates
duals_2015 AS (
  SELECT
    FIPS AS fips,
    SUM(Public_Total) AS duals_2015
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = DATE '2015-12-01'
  GROUP BY fips
),
duals_2018 AS (
  SELECT
    FIPS AS fips,
    SUM(Public_Total) AS duals_2018
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = DATE '2018-12-01'
  GROUP BY fips
),

-- counties whose dual‑eligible counts fell from 2015‑12‑01 → 2018‑12‑01
duals_decrease AS (
  SELECT d15.fips
  FROM duals_2015 d15
  JOIN duals_2018 d18 USING (fips)
  WHERE d18.duals_2018 < d15.duals_2015
)

-- final count: counties satisfying BOTH conditions
SELECT COUNT(*) AS counties_with_unemp_up_and_duals_down
FROM unemp_increase
JOIN duals_decrease USING (fips);
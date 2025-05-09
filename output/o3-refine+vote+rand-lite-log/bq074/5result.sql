WITH
-- Unemployment counts from 5‑year ACS
unemp_2015 AS (
  SELECT
    LPAD(CAST(geo_id AS STRING), 5, '0') AS fips,
    SAFE_CAST(unemployed_pop AS FLOAT64) AS unemployed_2015
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
),
unemp_2018 AS (
  SELECT
    LPAD(CAST(geo_id AS STRING), 5, '0') AS fips,
    SAFE_CAST(unemployed_pop AS FLOAT64) AS unemployed_2018
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),

-- Dual‑eligible enrollment (sum all program rows per county)
dual_2015 AS (
  SELECT
    LPAD(FIPS, 5, '0') AS fips,
    SUM(Public_Total) AS dual_2015
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE DATE = '2015-12-01'
  GROUP BY fips
),
dual_2018 AS (
  SELECT
    LPAD(FIPS, 5, '0') AS fips,
    SUM(Public_Total) AS dual_2018
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE DATE = '2018-12-01'
  GROUP BY fips
),

-- Combine all metrics
combined AS (
  SELECT
    u15.fips,
    u15.unemployed_2015,
    u18.unemployed_2018,
    d15.dual_2015,
    d18.dual_2018
  FROM unemp_2015 u15
  JOIN unemp_2018 u18 USING (fips)
  JOIN dual_2015 d15 USING (fips)
  JOIN dual_2018 d18 USING (fips)
)

-- Count counties meeting both conditions
SELECT
  COUNT(*) AS counties_with_rising_unemployment_and_falling_dual_eligibles
FROM combined
WHERE unemployed_2018 > unemployed_2015
  AND dual_2018 < dual_2015;
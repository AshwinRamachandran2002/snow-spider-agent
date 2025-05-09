-- number of counties with rising unemployment (2015→2018, 5‑yr ACS)
-- AND falling dual–eligible enrollment (Dec‑2015 → Dec‑2018)
WITH
-- 1.  Unemployment, 5‑year ACS
u15 AS (
  SELECT LPAD(geo_id,5,'0') AS fips,
         unemployed_pop AS unemployed_2015
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
),
u18 AS (
  SELECT LPAD(geo_id,5,'0') AS fips,
         unemployed_pop AS unemployed_2018
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),
unemp_increase AS (
  SELECT fips
  FROM u15
  JOIN u18 USING (fips)
  WHERE unemployed_2018 > unemployed_2015
),

-- 2.  Dual‑eligible enrollment (CMS), aggregate to county for the two dates
d15 AS (
  SELECT LPAD(FIPS,5,'0') AS fips,
         SUM(Public_Total) AS dual_2015
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2015-12-01'
  GROUP BY fips
),
d18 AS (
  SELECT LPAD(FIPS,5,'0') AS fips,
         SUM(Public_Total) AS dual_2018
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2018-12-01'
  GROUP BY fips
),
dual_decrease AS (
  SELECT fips
  FROM d15
  JOIN d18 USING (fips)
  WHERE dual_2018 < dual_2015
)

-- 3.  Final count of counties meeting BOTH conditions
SELECT COUNT(*) AS counties_with_unemp_up_and_duals_down
FROM unemp_increase
JOIN dual_decrease USING (fips);
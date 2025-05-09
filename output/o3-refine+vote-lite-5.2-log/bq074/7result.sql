-- number of counties whose unemployment rose (2015→2018, ACS 5‑yr)
-- and whose dual‑eligible enrollment fell (Dec‑2015→Dec‑2018, CMS)

WITH
-- unemployment (ACS 5‑yr)
unemp_2015 AS (
  SELECT
    LPAD(CAST(geo_id AS STRING),5,'0') AS fips,
    SAFE_CAST(unemployed_pop AS FLOAT64) AS unemp15
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
),
unemp_2018 AS (
  SELECT
    LPAD(CAST(geo_id AS STRING),5,'0') AS fips,
    SAFE_CAST(unemployed_pop AS FLOAT64) AS unemp18
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),
unemp_increase AS (      -- keep only counties with an increase
  SELECT  u18.fips
  FROM    unemp_2018 u18
  JOIN    unemp_2015 u15 USING (fips)
  WHERE   u18.unemp18 > u15.unemp15
),

-- dual‑eligible enrollment (CMS)
dual_2015 AS (
  SELECT
    LPAD(FIPS,5,'0') AS fips,
    SUM(Public_Total) AS dual15
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2015-12-01'
  GROUP BY fips
),
dual_2018 AS (
  SELECT
    LPAD(FIPS,5,'0') AS fips,
    SUM(Public_Total) AS dual18
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date = '2018-12-01'
  GROUP BY fips
),
dual_decrease AS (       -- keep only counties with a decrease
  SELECT  d18.fips
  FROM    dual_2018 d18
  JOIN    dual_2015 d15 USING (fips)
  WHERE   d18.dual18 < d15.dual15
)

-- final count of counties satisfying BOTH conditions
SELECT COUNT(*) AS counties_with_unemp_up_and_dual_down
FROM unemp_increase
JOIN dual_decrease USING (fips);
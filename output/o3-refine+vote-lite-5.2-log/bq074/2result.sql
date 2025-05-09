-- Count counties where (a) unemployment rose from 2015 to 2018
--  (ACS 5‑year county tables) AND (b) dual‑eligible enrollment fell
--  between Dec‑1‑2015 and Dec‑1‑2018 (CMS dual‑eligible file).

WITH
-- 1.  Unemployment levels in 2015 & 2018  (ACS 5‑year)
unemp_2015 AS (
  SELECT
    LPAD(CAST(geo_id AS STRING), 5, '0') AS fips,
    unemployed_pop                   AS unemployed_2015
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
),
unemp_2018 AS (
  SELECT
    LPAD(CAST(geo_id AS STRING), 5, '0') AS fips,
    unemployed_pop                   AS unemployed_2018
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),
unemp_increase AS (          -- counties with higher unemployment in 2018
  SELECT u15.fips
  FROM unemp_2015 u15
  JOIN unemp_2018 u18 USING (fips)
  WHERE u18.unemployed_2018 > u15.unemployed_2015
),

-- 2.  Dual‑eligible enrollee totals on the two required dates
dual_raw AS (
  SELECT
    LPAD(FIPS, 5, '0')           AS fips,
    Date,
    Public_Total
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date IN ('2015-12-01', '2018-12-01')              -- exact snapshots
),
dual_pivot AS (               -- reshape to one row per county
  SELECT
    fips,
    MAX(IF(Date = '2015-12-01', Public_Total, NULL)) AS total_2015,
    MAX(IF(Date = '2018-12-01', Public_Total, NULL)) AS total_2018
  FROM dual_raw
  GROUP BY fips
),
dual_decrease AS (            -- counties with lower enrollment in 2018
  SELECT fips
  FROM dual_pivot
  WHERE total_2015 IS NOT NULL
    AND total_2018 IS NOT NULL
    AND total_2018 < total_2015
)

-- 3.  Intersection of the two conditions & final count
SELECT COUNT(*) AS county_count
FROM unemp_increase
JOIN dual_decrease USING (fips);
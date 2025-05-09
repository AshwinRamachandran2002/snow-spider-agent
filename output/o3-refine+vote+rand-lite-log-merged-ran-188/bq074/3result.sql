-- number of counties where unemployment rose (2015→2018, ACS 5‑yr)
-- AND dual‑eligible enrollment fell (Dec‑2015→Dec‑2018)
WITH unemployment AS (
  SELECT
    CAST(geo_id AS STRING)           AS fips,
    SAFE_CAST(unemployed_pop AS FLOAT64) AS unemployed,
    2015 AS yr
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`

  UNION ALL

  SELECT
    CAST(geo_id AS STRING)           AS fips,
    SAFE_CAST(unemployed_pop AS FLOAT64) AS unemployed,
    2018 AS yr
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
),
unemployment_change AS (
  SELECT
    fips,
    MAX(CASE WHEN yr = 2015 THEN unemployed END) AS unem_2015,
    MAX(CASE WHEN yr = 2018 THEN unemployed END) AS unem_2018
  FROM unemployment
  GROUP BY fips
  HAVING unem_2018 > unem_2015                     -- increase
),

dual_enrollment AS (
  SELECT
    FIPS                                         AS fips,
    Public_Total                                 AS enrollee_cnt,
    EXTRACT(YEAR FROM Date)                      AS yr
  FROM `bigquery-public-data.sdoh_cms_dual_eligible_enrollment.dual_eligible_enrollment_by_county_and_program`
  WHERE Date IN ('2015-12-01','2018-12-01')       -- use specified snapshots
),
dual_change AS (
  SELECT
    fips,
    MAX(CASE WHEN yr = 2015 THEN enrollee_cnt END) AS dual_2015,
    MAX(CASE WHEN yr = 2018 THEN enrollee_cnt END) AS dual_2018
  FROM dual_enrollment
  GROUP BY fips
  HAVING dual_2018 < dual_2015                     -- decrease
)

SELECT
  COUNT(DISTINCT u.fips) AS counties_meeting_criteria
FROM unemployment_change  AS u
JOIN dual_change          AS d
ON  u.fips = d.fips;
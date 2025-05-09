WITH snap_2017 AS (
  SELECT
    LPAD(CAST(FIPS AS STRING), 5, '0')           AS county_fips,
    SUM(SNAP_All_Participation_Households)       AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'
  GROUP BY county_fips
  HAVING snap_households > 0
),
county_income AS (
  SELECT
    geo_id                                         AS county_fips,
    COALESCE(SAFE_CAST(income_less_10000      AS NUMERIC), 0) +
    COALESCE(SAFE_CAST(income_10000_14999     AS NUMERIC), 0) +
    COALESCE(SAFE_CAST(income_15000_19999     AS NUMERIC), 0) AS low_income_households
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  s.county_fips,
  s.snap_households,
  c.low_income_households,
  c.low_income_households / s.snap_households AS low_income_to_snap_ratio
FROM snap_2017 s
JOIN county_income c
  ON s.county_fips = c.county_fips
ORDER BY s.snap_households DESC
LIMIT 10;
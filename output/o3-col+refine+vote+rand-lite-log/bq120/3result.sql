WITH snap17 AS (
  -- Total SNAP-participating households per county (Jan-01-2017 only)
  SELECT
    SUBSTR(GeoDesc, 1, 5) AS county_fips,
    SUM(SNAP_All_Participation_Households) AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'
  GROUP BY county_fips
),
acs17 AS (
  -- Households earning < $20k from the 2017 5-year ACS county table
  SELECT
    geo_id,
    COALESCE(income_less_10000, 0) +
    COALESCE(income_10000_14999, 0) +
    COALESCE(income_15000_19999, 0) AS hh_under_20k
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  s.county_fips                       AS county_geo_id,
  s.snap_households                   AS total_snap_households,
  a.hh_under_20k                      AS households_under_20k_income,
  SAFE_DIVIDE(a.hh_under_20k, s.snap_households) AS under20k_to_snap_ratio
FROM snap17 AS s
JOIN acs17  AS a
  ON a.geo_id = s.county_fips
WHERE s.snap_households > 0
ORDER BY total_snap_households DESC
LIMIT 10;
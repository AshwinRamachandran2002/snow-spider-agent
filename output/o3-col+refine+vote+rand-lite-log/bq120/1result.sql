-- Top 10 counties by SNAP-participating households (1-Jan-2017)
-- and ratio of <$20 K-income households to SNAP households
WITH snap_by_county AS (
  SELECT
    SUBSTR(`GeoDesc`, 1, 5)            AS county_fips,
    SUM(`SNAP_All_Participation_Households`) AS total_snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE `Date` = '2017-01-01'
  GROUP BY county_fips
  HAVING total_snap_households > 0
),
acs_under20k AS (
  SELECT
    `geo_id`,
    (`income_less_10000`
     + `income_10000_14999`
     + `income_15000_19999`)          AS under_20k_households
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  s.county_fips,
  s.total_snap_households,
  a.under_20k_households,
  SAFE_DIVIDE(a.under_20k_households, s.total_snap_households)
    AS under20k_to_snap_ratio
FROM snap_by_county AS s
JOIN acs_under20k AS a
  ON a.geo_id = s.county_fips
ORDER BY s.total_snap_households DESC
LIMIT 10;
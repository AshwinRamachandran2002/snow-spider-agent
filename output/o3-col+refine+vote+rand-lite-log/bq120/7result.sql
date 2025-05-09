-- Top-10 counties by SNAP-participating households (1-Jan-2017)
WITH snap AS (
  SELECT
    SUBSTR(`GeoDesc`, 1, 5) AS county_fips,
    SUM(`SNAP_All_Participation_Households`) AS total_snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE `Date` = '2017-01-01'
  GROUP BY county_fips
  HAVING total_snap_households > 0
),
acs AS (
  SELECT
    `geo_id` AS county_fips,
    (`income_less_10000`
     + `income_10000_14999`
     + `income_15000_19999`)          AS households_under_20000
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)

SELECT
  s.county_fips,
  s.total_snap_households,
  a.households_under_20000,
  ROUND(
    SAFE_DIVIDE(a.households_under_20000, s.total_snap_households),
    4
  ) AS ratio_under20k_to_snap
FROM snap AS s
JOIN acs  AS a
USING (county_fips)
ORDER BY s.total_snap_households DESC
LIMIT 10;
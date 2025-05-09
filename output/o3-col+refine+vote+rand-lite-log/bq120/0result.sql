WITH snap AS (
  -- Aggregate SNAP–participating households to the county-FIPS level
  SELECT
    SUBSTR(GeoDesc, 1, 5) AS county_fips,
    SUM(SNAP_All_Participation_Households) AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'
  GROUP BY county_fips
  HAVING snap_households > 0              -- exclude counties with zero SNAP households
)

SELECT
  c.geo_id                                   AS county_fips,
  s.snap_households,
  -- households earning < $20 000
  COALESCE(c.income_less_10000,0)
+ COALESCE(c.income_10000_14999,0)
+ COALESCE(c.income_15000_19999,0)            AS households_under_20k,
  -- ratio of < $20 k households to SNAP-participating households
  SAFE_DIVIDE(
    COALESCE(c.income_less_10000,0)
  + COALESCE(c.income_10000_14999,0)
  + COALESCE(c.income_15000_19999,0),
    s.snap_households
  )                                           AS ratio_under20k_to_snap
FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr` AS c
JOIN snap AS s
ON c.geo_id = s.county_fips
ORDER BY s.snap_households DESC               -- top 10 counties by SNAP households
LIMIT 10;
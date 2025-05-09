-- Top 10 counties with the highest number of SNAP-participating households
-- (Jan 1 2017) and the ratio of households earning under $20 000 to those
-- SNAP households, using 2017 5-year ACS county data.

WITH snap_2017 AS (
  SELECT
    SUBSTR(GeoDesc, 1, 5) AS county_fips,
    SUM(SNAP_All_Participation_Households) AS snap_households_20170101
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'
  GROUP BY county_fips
  HAVING snap_households_20170101 > 0
)

SELECT
  c.geo_id AS county_fips,
  s.snap_households_20170101 AS snap_households,
  (COALESCE(c.income_less_10000, 0) +
   COALESCE(c.income_10000_14999, 0) +
   COALESCE(c.income_15000_19999, 0)) AS households_under_20k,
  ROUND(
    (COALESCE(c.income_less_10000, 0) +
     COALESCE(c.income_10000_14999, 0) +
     COALESCE(c.income_15000_19999, 0)) /
    s.snap_households_20170101, 4) AS under20k_to_snap_ratio
FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr` AS c
JOIN snap_2017 AS s
  ON c.geo_id = s.county_fips
ORDER BY s.snap_households_20170101 DESC
LIMIT 10;
-- Top 10 counties by SNAP-participating households on 2017-01-01
WITH acs AS (
  SELECT
    geo_id AS county_fips,
    households,
    (income_less_10000 + income_10000_14999 + income_15000_19999) AS households_under_20k
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
snap AS (
  SELECT
    SUBSTR(GeoDesc, 1, 5) AS county_fips,
    SUM(SNAP_All_Participation_Households) AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'
  GROUP BY county_fips
  HAVING snap_households > 0
)
SELECT
  s.county_fips,
  s.snap_households,
  a.households_under_20k,
  ROUND(a.households_under_20k / s.snap_households, 4) AS under20k_to_snap_ratio
FROM snap AS s
JOIN acs  AS a
USING (county_fips)
ORDER BY s.snap_households DESC
LIMIT 10;
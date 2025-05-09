/*  Top 10 counties by SNAP–participating households (01-Jan-2017)
    and ratio of ACS-2017 (<$20 K income households) to SNAP households   */

WITH snap AS (
  SELECT
    SUBSTR(GeoDesc, 1, 5)                                       AS county_fips,
    ANY_VALUE(REGEXP_EXTRACT(GeoDesc, r'EBT\s+(.+)$'))          AS county_name,
    SUM(SNAP_All_Participation_Households)                      AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'
  GROUP BY county_fips
  HAVING snap_households > 0
),
acs AS (
  SELECT
    geo_id                                                      AS county_fips,
    (IFNULL(income_less_10000, 0) +
     IFNULL(income_10000_14999, 0) +
     IFNULL(income_15000_19999, 0))                             AS households_under_20k
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  s.county_name,
  s.county_fips,
  s.snap_households,
  a.households_under_20k,
  ROUND(SAFE_DIVIDE(a.households_under_20k, s.snap_households), 3) AS under20k_to_snap_ratio
FROM snap AS s
JOIN acs  AS a USING (county_fips)
ORDER BY s.snap_households DESC
LIMIT 10;
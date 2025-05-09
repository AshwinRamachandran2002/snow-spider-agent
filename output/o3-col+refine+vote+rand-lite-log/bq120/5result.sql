WITH snap_by_county AS (
  -- Aggregate SNAP-participating households by 5-digit county FIPS
  SELECT
    SUBSTR(GeoDesc, 1, 5)                          AS county_fips,
    SUM(SNAP_All_Participation_Households)         AS total_snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'                        -- January 1 2017 snapshot
  GROUP BY county_fips
),
acs_2017 AS (
  -- Pull income buckets from the 2017 5-year ACS county table
  SELECT
    geo_id,
    COALESCE(income_less_10000,      0) AS income_less_10000,
    COALESCE(income_10000_14999,     0) AS income_10000_14999,
    COALESCE(income_15000_19999,     0) AS income_15000_19999
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)

SELECT
  s.county_fips                                                        AS geo_id,
  s.total_snap_households,
  (a.income_less_10000 + a.income_10000_14999 + a.income_15000_19999)  AS households_under_20k,
  SAFE_DIVIDE(
    (a.income_less_10000 + a.income_10000_14999 + a.income_15000_19999),
    s.total_snap_households
  )                                                                    AS under_20k_to_snap_ratio
FROM snap_by_county AS s
JOIN acs_2017 AS a
  ON s.county_fips = a.geo_id
WHERE s.total_snap_households > 0
ORDER BY s.total_snap_households DESC
LIMIT 10;
-- Top 10 counties by SNAP–participating households (Jan‑01‑2017) 
--   and ratio of < $20 k‑income households to SNAP households  
WITH acs AS (
  SELECT
    CAST(geo_id AS STRING)                                         AS fips,
    COALESCE(income_less_10000 ,0)
  + COALESCE(income_10000_14999,0)
  + COALESCE(income_15000_19999,0)                                AS households_under_20k
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
snap AS (
  SELECT
    FIPS                                                          AS fips,
    SUM(SNAP_All_Participation_Households)                        AS snap_households,
    ANY_VALUE(GeoDesc)                                            AS county_name
  FROM  `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'
  GROUP BY fips
),
combined AS (
  SELECT
    s.county_name,
    s.fips,
    s.snap_households,
    a.households_under_20k,
    SAFE_DIVIDE(a.households_under_20k , s.snap_households)       AS under_20k_to_snap_ratio
  FROM snap s
  JOIN acs  a USING (fips)
  WHERE s.snap_households > 0          -- exclude zero‑SNAP counties
)
SELECT
  county_name,
  fips,
  snap_households,
  households_under_20k,
  ROUND(under_20k_to_snap_ratio,4)     AS under_20k_to_snap_ratio
FROM combined
ORDER BY snap_households DESC, fips
LIMIT 10;
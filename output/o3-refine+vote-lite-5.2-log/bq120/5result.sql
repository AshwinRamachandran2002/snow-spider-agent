WITH snap AS (
  -- 1.  SNAP‑participating households by county (Jan‑01‑2017)
  SELECT
    FIPS,                                     -- 5–digit county FIPS
    SUM(SNAP_All_Participation_Households) AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'                  -- January 1 2017 snapshot
    AND SNAP_All_Participation_Households > 0
  GROUP BY FIPS
),
acs AS (
  -- 2.  Income counts from 2017 5‑year ACS (county level)
  SELECT
    CAST(geo_id AS STRING)                                   AS FIPS,
    SAFE_CAST(income_less_10000   AS FLOAT64)                AS inc_u10k,
    SAFE_CAST(income_10000_14999  AS FLOAT64)                AS inc_10_15k,
    SAFE_CAST(income_15000_19999  AS FLOAT64)                AS inc_15_20k
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
-- 3.  Join and rank
SELECT
  s.FIPS,
  s.snap_households,
  (a.inc_u10k + a.inc_10_15k + a.inc_15_20k)                AS households_under_20k,
  ROUND( (a.inc_u10k + a.inc_10_15k + a.inc_15_20k)
         / s.snap_households , 4)                           AS ratio_under20k_to_snap
FROM snap s
JOIN acs  a USING (FIPS)
ORDER BY s.snap_households DESC, s.FIPS
LIMIT 10;
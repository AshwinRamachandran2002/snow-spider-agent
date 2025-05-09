-- Top 10 counties (FIPS) by SNAP‑participating households on 2017‑01‑01
-- plus ratio of ACS 2017 5‑yr households earning < $20 k to SNAP households
WITH snap AS (
  SELECT
    FIPS,
    SUM(SNAP_All_Participation_Households) AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'          -- January 1 2017 snapshot
  GROUP BY FIPS
),
acs AS (
  SELECT
    geo_id AS FIPS,
    COALESCE(income_less_10000,0)
    + COALESCE(income_10000_14999,0)
    + COALESCE(income_15000_19999,0) AS under_20k_households
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  snap.FIPS                                   AS county_fips,
  snap.snap_households,
  acs.under_20k_households,
  SAFE_DIVIDE(acs.under_20k_households,
              snap.snap_households)           AS under_20k_to_snap_ratio
FROM snap
JOIN acs USING (FIPS)
WHERE snap.snap_households > 0                -- exclude zero‑SNAP counties
ORDER BY snap.snap_households DESC
LIMIT 10;
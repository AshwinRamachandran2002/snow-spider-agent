WITH snap_2017 AS (
  /* 1.  SNAP‑participating households on 2017‑01‑01                       */
  SELECT
    FIPS                       AS county_fips,
    SUM(SNAP_All_Participation_Households) AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'        -- 1 Jan 2017
  GROUP BY county_fips
),
acs_2017 AS (
  /* 2.  Household counts by income for the 2017 5‑year ACS (county)      */
  SELECT
    geo_id                      AS county_fips,
    COALESCE(income_less_10000, 0)
    + COALESCE(income_10000_14999, 0)
    + COALESCE(income_15000_19999, 0)         AS hh_under_20k
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
fips_name AS (
  /* 3.  County names                                                     */
  SELECT
    GeoFIPS   AS county_fips,
    GeoName   AS county_name
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE Year = '2017-01-01'
)
SELECT
  fn.county_name,
  j.county_fips,
  j.snap_households,
  j.hh_under_20k,
  SAFE_DIVIDE(j.hh_under_20k, j.snap_households) AS ratio_under20k_to_snap
FROM (
  /* 4.  Join SNAP & ACS, require SNAP > 0                                */
  SELECT
    acs.county_fips,
    acs.hh_under_20k,
    snap.snap_households
  FROM acs_2017 AS acs
  JOIN snap_2017 AS snap
    ON acs.county_fips = snap.county_fips
  WHERE snap.snap_households > 0
) AS j
LEFT JOIN fips_name AS fn
  ON j.county_fips = fn.county_fips
ORDER BY
  j.snap_households DESC
LIMIT 10;
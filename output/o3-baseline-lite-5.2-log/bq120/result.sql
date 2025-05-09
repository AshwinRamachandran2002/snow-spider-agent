-- Top 10 counties by SNAP–participating households (Jan‑01‑2017)
-- with ratio of households earning < $20 000 to SNAP households
WITH snap_2017 AS (
  SELECT
    FIPS,                                         -- 5‑digit county FIPS
    SUM(SNAP_All_Participation_Households) AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'
  GROUP BY FIPS
),
acs_2017 AS (
  SELECT
    LPAD(geo_id, 5, '0')        AS FIPS,         -- ensure 5‑digit format
    (income_less_10000
     + income_10000_14999
     + income_15000_19999)      AS hh_under_20k  -- households < $20 000
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  a.FIPS                     AS county_fips,
  s.snap_households,
  a.hh_under_20k,
  a.hh_under_20k / s.snap_households AS ratio_under20k_to_snap
FROM acs_2017 a
JOIN snap_2017 s USING (FIPS)
WHERE s.snap_households > 0
ORDER BY s.snap_households DESC, county_fips
LIMIT 10;
WITH snap_2017 AS (
  -- SNAP‑participating households by county on Jan‑01‑2017
  SELECT
    `FIPS`                                         AS fips,
    SUM(`SNAP_All_Participation_Households`)       AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE `Date` = '2017-01-01'
  GROUP BY fips
),
acs_2017 AS (
  -- Households earning < $20 000 from the 2017 ACS 5‑year county file
  SELECT
    `geo_id` AS fips,
    (`income_less_10000`
     + `income_10000_14999`
     + `income_15000_19999`)                      AS hh_under_20k
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)

SELECT
  s.fips,
  s.snap_households,
  a.hh_under_20k,
  ROUND(SAFE_DIVIDE(a.hh_under_20k, s.snap_households), 4) AS under20k_to_snap_ratio
FROM snap_2017 AS s
JOIN acs_2017  AS a
  ON s.fips = a.fips
WHERE s.snap_households > 0            -- exclude counties with zero SNAP enrollment
ORDER BY s.snap_households DESC
LIMIT 10;
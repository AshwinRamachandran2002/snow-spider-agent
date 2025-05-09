WITH
-- 1.  County‑level household counts earning < $20K (2017 ACS 5‑year)
county_income AS (
  SELECT
    CAST(`geo_id` AS STRING)            AS county_fips,
    (COALESCE(`income_less_10000`,0) +
     COALESCE(`income_10000_14999`,0) +
     COALESCE(`income_15000_19999`,0)) AS households_under_20k
  FROM
    `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),

-- 2.  SNAP‑participating households on 1 Jan 2017
snap_2017 AS (
  SELECT
    CAST(`FIPS` AS STRING)                       AS county_fips,
    COALESCE(`SNAP_All_Participation_Households`,0) AS snap_households
  FROM
    `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE
    `Date` = DATE '2017-01-01'          -- 1 Jan 2017 snapshot
)

-- 3.  Combine, rank, and compute ratio
SELECT
  county_fips,
  snap_households,
  households_under_20k,
  SAFE_DIVIDE( households_under_20k , snap_households ) AS under20k_to_snap_ratio
FROM
  snap_2017  AS s
JOIN
  county_income AS c
USING (county_fips)
WHERE
  snap_households > 0
ORDER BY
  snap_households DESC,
  county_fips
LIMIT 10;
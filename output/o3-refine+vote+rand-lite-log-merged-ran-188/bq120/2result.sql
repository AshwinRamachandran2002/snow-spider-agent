-- top 10 counties by SNAP–participating households (Jan‑01‑2017)  
-- and ratio of < $20k‑income households to SNAP households  
WITH
/* 1.  2017 ACS 5‑year county–level: households with income < $20 000 */
acs AS (
  SELECT
    geo_id                                   AS fips,
    SAFE_CAST(income_less_10000     AS FLOAT64) +
    SAFE_CAST(income_10000_14999    AS FLOAT64) +
    SAFE_CAST(income_15000_19999    AS FLOAT64)     AS households_under_20k
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),

/* 2.  SNAP enrolment on 2017‑01‑01 – sum to county level            */
snap AS (
  SELECT
    FIPS                                     AS fips,
    SUM(SNAP_All_Participation_Households)   AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = '2017-01-01'
  GROUP BY fips
),

/* 3.  County names (BEA CAINC30, 2017)                               */
names AS (
  SELECT
    GeoFIPS                     AS fips,
    MAX(GeoName)                AS county_name
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE Year = '2017-01-01'
  GROUP BY fips
)

/* 4.  Assemble, compute ratio, rank                                 */
SELECT
  n.county_name,
  a.fips,
  s.snap_households,
  a.households_under_20k,
  a.households_under_20k / s.snap_households AS under20k_to_snap_ratio
FROM acs a
JOIN snap s USING (fips)
JOIN names n USING (fips)
WHERE s.snap_households > 0
ORDER BY s.snap_households DESC
LIMIT 10;
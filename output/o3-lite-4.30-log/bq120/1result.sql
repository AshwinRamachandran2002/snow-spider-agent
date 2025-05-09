WITH snap_2017 AS (
  -- SNAP‑participating households per county (FIPS) on 2017‑01‑01
  SELECT
    FIPS AS county_fips,
    ANY_VALUE(SPLIT(GeoDesc, ' ')[OFFSET(1)]) AS state,  -- state abbreviation
    SUM(SNAP_All_Participation_Households) AS snap_households
  FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE Date = DATE '2017-01-01'
    -- keep only 5‑digit county FIPS, exclude state‑level totals ending in '000'
    AND LENGTH(FIPS) = 5
    AND SUBSTR(FIPS, 3, 3) <> '000'
  GROUP BY county_fips
  HAVING snap_households > 0
),
acs_income AS (
  -- households earning < $20 000 from 2017 5‑yr ACS
  SELECT
    geo_id AS county_fips,
    (income_less_10000 + income_10000_14999 + income_15000_19999)
      AS households_under_20k
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  s.county_fips AS county,
  s.state,
  ROUND(
    SAFE_DIVIDE(a.households_under_20k, s.snap_households),
    4
  ) AS ratio_under_20k_to_snap_households
FROM snap_2017 AS s
JOIN acs_income AS a
  USING (county_fips)
ORDER BY s.snap_households DESC, county
LIMIT 10;
WITH snap AS (
  SELECT
    FIPS,
    SUM(SNAP_All_Participation_Households) AS snap_households
  FROM
    `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment`
  WHERE
    Date = '2017-01-01'
  GROUP BY
    FIPS
),
acs AS (
  SELECT
    geo_id,
    (income_less_10000 + income_10000_14999 + income_15000_19999) AS under20k_households
  FROM
    `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  s.FIPS                                AS county_fips,
  s.snap_households,
  a.under20k_households,
  ROUND(a.under20k_households / s.snap_households, 4) AS ratio_under20k_to_snap
FROM
  snap s
JOIN
  acs  a
ON
  a.geo_id = s.FIPS
WHERE
  s.snap_households > 0
ORDER BY
  s.snap_households DESC
LIMIT 10;
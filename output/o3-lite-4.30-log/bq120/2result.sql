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
    (income_less_10000 + income_10000_14999 + income_15000_19999) AS under_20k_households
  FROM
    `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  s.FIPS                                                   AS county,
  SUBSTR(s.FIPS, 1, 2)                                     AS state,
  ROUND(SAFE_DIVIDE(a.under_20k_households, s.snap_households), 4)
                                                           AS ratio_under_20k_to_snap_households
FROM
  snap AS s
JOIN
  acs  AS a
ON  s.FIPS = a.geo_id
WHERE
  s.snap_households > 0
ORDER BY
  s.snap_households DESC,
  s.FIPS
LIMIT 10;
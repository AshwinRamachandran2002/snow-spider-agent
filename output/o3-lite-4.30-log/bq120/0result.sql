SELECT
  snap.FIPS AS county,
  SPLIT(snap.GeoDesc, ' ')[OFFSET(1)] AS state,
  ROUND(
    SAFE_DIVIDE(
      COALESCE(acs.income_less_10000, 0) +
      COALESCE(acs.income_10000_14999, 0) +
      COALESCE(acs.income_15000_19999, 0),
      snap.SNAP_All_Participation_Households
    ), 4
  ) AS ratio_under_20k_to_snap_households
FROM `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment` AS snap
JOIN `bigquery-public-data.census_bureau_acs.county_2017_5yr` AS acs
  ON snap.FIPS = acs.geo_id
WHERE snap.Date = '2017-01-01'
  AND snap.SNAP_All_Participation_Households > 0
ORDER BY snap.SNAP_All_Participation_Households DESC
LIMIT 10;
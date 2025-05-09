SELECT
  s.GeoDesc AS Region_Name,
  SUM(s.SNAP_All_Participation_Households) AS total_snap_households,
  ROUND(
    (SUM(c.income_less_10000) + SUM(c.income_10000_14999) + SUM(c.income_15000_19999)) / SUM(s.SNAP_All_Participation_Households),
    4
  ) AS ratio_under_20k_to_snap_households
FROM
  `bigquery-public-data.sdoh_snap_enrollment.snap_enrollment` AS s
JOIN
  `bigquery-public-data.census_bureau_acs.county_2017_5yr` AS c
ON
  s.FIPS = RIGHT(c.geo_id, 5)
WHERE
  EXTRACT(YEAR FROM s.Date) = 2017
GROUP BY
  Region_Name
ORDER BY
  total_snap_households DESC
LIMIT 10;
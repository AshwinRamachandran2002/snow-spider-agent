SELECT
  c.county_name AS County,
  ROUND(((q2018.month3_emplvl_23_construction - q2000.month3_emplvl_23_construction) / q2000.month3_emplvl_23_construction) * 100, 4) AS Percentage_Increase
FROM
  `bigquery-public-data.geo_us_boundaries.counties` AS c
JOIN
  `bigquery-public-data.bls_qcew.2000_q1` AS q2000
ON
  c.geo_id = q2000.geoid
JOIN
  `bigquery-public-data.bls_qcew.2018_q4` AS q2018
ON
  c.geo_id = q2018.geoid
WHERE
  c.state_fips_code = '49'
  AND q2000.month3_emplvl_23_construction IS NOT NULL
  AND q2000.month3_emplvl_23_construction > 0
  AND q2018.month3_emplvl_23_construction IS NOT NULL
ORDER BY
  Percentage_Increase DESC
LIMIT 1;
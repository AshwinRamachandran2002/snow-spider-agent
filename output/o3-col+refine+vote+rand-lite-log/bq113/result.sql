/* Utah county with the largest 2000-to-2018 % increase in construction employment */
WITH yr2000 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS emp_2000
  FROM (
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q1`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q2`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q3`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q4`
  )
  WHERE SUBSTR(area_fips, 1, 2) = '49'          -- Utah
  GROUP BY area_fips
),
yr2018 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS emp_2018
  FROM (
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q1`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q2`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q3`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q4`
  )
  WHERE SUBSTR(area_fips, 1, 2) = '49'
  GROUP BY area_fips
),
pct_change AS (
  SELECT
    a.area_fips,
    SAFE_DIVIDE(b.emp_2018 - a.emp_2000, a.emp_2000) * 100 AS pct_increase
  FROM yr2000 a
  JOIN yr2018 b USING (area_fips)
)
SELECT
  c.county_name AS county,
  ROUND(pct_increase, 2) AS pct_increase
FROM pct_change pc
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.geo_id = pc.area_fips
ORDER BY pct_increase DESC
LIMIT 1;
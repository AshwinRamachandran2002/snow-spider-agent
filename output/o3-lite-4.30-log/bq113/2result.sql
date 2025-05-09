WITH utah_2000 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_2000
  FROM (
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q1`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q2`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q3`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q4`
  )
  WHERE area_fips LIKE '49%'
  GROUP BY area_fips
),
utah_2018 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_2018
  FROM (
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q1`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q2`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q3`
    UNION ALL
    SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q4`
  )
  WHERE area_fips LIKE '49%'
  GROUP BY area_fips
),
growth AS (
  SELECT
    u18.area_fips,
    SAFE_DIVIDE(u18.avg_2018 - u00.avg_2000, u00.avg_2000) * 100 AS pct_increase
  FROM utah_2018 u18
  JOIN utah_2000 u00 USING (area_fips)
)
SELECT
  c.county_name                          AS county,
  ROUND(g.pct_increase, 4)               AS percentage_increase
FROM growth g
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON g.area_fips = c.county_fips_code
WHERE c.state_fips_code = '49'
ORDER BY percentage_increase DESC
LIMIT 1;
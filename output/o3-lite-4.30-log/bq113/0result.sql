WITH yr2000 AS (
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
  WHERE LEFT(area_fips, 2) = '49'
  GROUP BY area_fips
),
yr2018 AS (
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
  WHERE LEFT(area_fips, 2) = '49'
  GROUP BY area_fips
),
pct_change AS (
  SELECT
    c.county_name AS county,
    100 * (y18.avg_2018 - y00.avg_2000) / y00.avg_2000 AS percentage_increase
  FROM yr2000 y00
  JOIN yr2018 y18 USING (area_fips)
  JOIN `bigquery-public-data.geo_us_boundaries.counties` c
    ON c.county_fips_code = y00.area_fips AND c.state_fips_code = '49'
  WHERE y00.avg_2000 > 0  -- avoid division by zero
)
SELECT
  county,
  ROUND(percentage_increase, 4) AS percentage_increase
FROM pct_change
ORDER BY percentage_increase DESC
LIMIT 1;
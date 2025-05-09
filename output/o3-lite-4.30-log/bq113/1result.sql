WITH yr2000 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_2000_emp
  FROM (
        SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q1`
        UNION ALL
        SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q2`
        UNION ALL
        SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q3`
        UNION ALL
        SELECT area_fips, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q4`
       )
  WHERE area_fips LIKE '49%'          -- Utah counties (state FIPS 49)
  GROUP BY area_fips
),
yr2018 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_2018_emp
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
    y2.area_fips,
    SAFE_DIVIDE(y2.avg_2018_emp - y1.avg_2000_emp, y1.avg_2000_emp) * 100 AS pct_increase
  FROM yr2000 y1
  JOIN yr2018 y2 USING (area_fips)
)
SELECT
  c.county_name AS county,
  ROUND(g.pct_increase, 4) AS percentage_increase
FROM growth g
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.geo_id = g.area_fips
ORDER BY percentage_increase DESC
LIMIT 1;
-- Utah county with the largest 2000-to-2018 percentage increase in
-- construction employment (March-level average of each quarter)

WITH yearly_avg AS (
  -- ---- 2000 ----
  SELECT
    '2000' AS yr,
    geoid,
    AVG(month3_emplvl_23_construction) AS avg_emp
  FROM (
    SELECT geoid, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q1`
    UNION ALL
    SELECT geoid, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q2`
    UNION ALL
    SELECT geoid, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q3`
    UNION ALL
    SELECT geoid, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2000_q4`
  )
  WHERE geoid LIKE '49%'                -- Utah counties (state-FIPS 49)
  GROUP BY geoid

  UNION ALL

  -- ---- 2018 ----
  SELECT
    '2018' AS yr,
    geoid,
    AVG(month3_emplvl_23_construction) AS avg_emp
  FROM (
    SELECT geoid, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q1`
    UNION ALL
    SELECT geoid, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q2`
    UNION ALL
    SELECT geoid, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q3`
    UNION ALL
    SELECT geoid, month3_emplvl_23_construction FROM `bigquery-public-data.bls_qcew.2018_q4`
  )
  WHERE geoid LIKE '49%'
  GROUP BY geoid
),

-- pivot to one row per county
pivot AS (
  SELECT
    geoid,
    MAX(IF(yr='2000', avg_emp, NULL)) AS avg_emp_2000,
    MAX(IF(yr='2018', avg_emp, NULL)) AS avg_emp_2018
  FROM yearly_avg
  GROUP BY geoid
),

-- compute percentage growth
growth AS (
  SELECT
    geoid,
    SAFE_DIVIDE(avg_emp_2018 - avg_emp_2000, avg_emp_2000) * 100 AS pct_growth
  FROM pivot
)

SELECT
  cnt.county_name,
  ROUND(g.pct_growth, 4) AS percentage_increase
FROM growth g
JOIN `bigquery-public-data.geo_us_boundaries.counties` cnt
  ON cnt.geo_id = g.geoid
ORDER BY pct_growth DESC
LIMIT 1;
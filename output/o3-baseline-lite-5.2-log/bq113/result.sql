WITH ut_counties AS (
  -- list of Utah counties with their 5‑digit FIPS code
  SELECT county_fips_code AS geoid,
         county_name
  FROM `bigquery-public-data.geo_us_boundaries.counties`
  WHERE state_fips_code = '49'
),
-- average construction employment (third‑month level) for 2000
emp_2000 AS (
  SELECT
    geoid,
    AVG(month3_emplvl_23_construction) AS avg_emp_2000
  FROM `bigquery-public-data.bls_qcew.2000_q*`
  WHERE month3_emplvl_23_construction IS NOT NULL
  GROUP BY geoid
),
-- average construction employment (third‑month level) for 2018
emp_2018 AS (
  SELECT
    geoid,
    AVG(month3_emplvl_23_construction) AS avg_emp_2018
  FROM `bigquery-public-data.bls_qcew.2018_q*`
  WHERE month3_emplvl_23_construction IS NOT NULL
  GROUP BY geoid
),
-- compute percentage change between 2000 and 2018
growth AS (
  SELECT
    c.county_name,
    (e18.avg_emp_2018 - e00.avg_emp_2000) / e00.avg_emp_2000 * 100 AS pct_increase
  FROM emp_2000 e00
  JOIN emp_2018 e18 USING (geoid)
  JOIN ut_counties c USING (geoid)
  WHERE e00.avg_emp_2000 > 0        -- avoid division by zero
)
SELECT
  county_name,
  ROUND(pct_increase, 4) AS pct_increase
FROM growth
ORDER BY pct_increase DESC
LIMIT 1;
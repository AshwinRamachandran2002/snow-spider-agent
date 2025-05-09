/*  Utah county with the greatest % increase in construction employment
    (average of “month‑3” employment for each quarter) from 2000 to 2018  */
WITH quarterly AS (
  SELECT
    area_fips,                                        -- county FIPS
    SUBSTR(_TABLE_SUFFIX,1,4) AS yr,                  -- 2000 / 2018
    month3_emplvl_23_construction   AS march_emp
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('2000_q1','2000_q2','2000_q3','2000_q4',
                          '2018_q1','2018_q2','2018_q3','2018_q4')
    AND area_fips LIKE '49%'                          -- Utah counties
),
yearly AS (   -- average of the four quarter‑3‑month values in each year
  SELECT
    area_fips,
    yr,
    AVG(march_emp) AS avg_march_emp
  FROM quarterly
  GROUP BY area_fips, yr
),
pivot AS (    -- place the two years side by side
  SELECT
    area_fips,
    MAX(IF(yr='2000', avg_march_emp, NULL)) AS emp_2000,
    MAX(IF(yr='2018', avg_march_emp, NULL)) AS emp_2018
  FROM yearly
  GROUP BY area_fips
),
growth AS (
  SELECT
    area_fips,
    SAFE_DIVIDE(emp_2018 - emp_2000, emp_2000) * 100 AS pct_increase
  FROM pivot
  WHERE emp_2000 IS NOT NULL AND emp_2018 IS NOT NULL
)
SELECT
  c.county_name AS county,
  ROUND(g.pct_increase,2) AS percent_increase
FROM growth g
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.geo_id = g.area_fips
WHERE c.state_fips_code = '49'      -- Utah
ORDER BY percent_increase DESC
LIMIT 1;
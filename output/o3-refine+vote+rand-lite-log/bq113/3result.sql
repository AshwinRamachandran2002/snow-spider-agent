-- Greatest percentage increase in construction employment (month‑3 levels)
-- from 2000 to 2018 among Utah counties
WITH all_qcew AS (
  -- grab month‑3 construction employment for the two target years
  SELECT area_fips,
         2000 AS yr,
         month3_emplvl_23_construction AS emp
  FROM  `bigquery-public-data.bls_qcew.2000_q*`
  UNION ALL
  SELECT area_fips,
         2018 AS yr,
         month3_emplvl_23_construction AS emp
  FROM  `bigquery-public-data.bls_qcew.2018_q*`
),
yearly_avg AS (      -- average the four quarter‑3 values for each year
  SELECT area_fips,
         yr,
         AVG(emp) AS avg_emp
  FROM   all_qcew
  GROUP  BY area_fips, yr
),
pivoted AS (         -- place the two years side‑by‑side
  SELECT area_fips,
         MAX(CASE WHEN yr = 2000 THEN avg_emp END) AS emp_2000,
         MAX(CASE WHEN yr = 2018 THEN avg_emp END) AS emp_2018
  FROM   yearly_avg
  GROUP  BY area_fips
),
utah_only AS (       -- keep Utah counties and compute % increase
  SELECT c.county_name,
         emp_2000,
         emp_2018,
         SAFE_DIVIDE(emp_2018 - emp_2000, emp_2000) * 100 AS pct_increase
  FROM   pivoted p
  JOIN   `bigquery-public-data.geo_us_boundaries.counties` c
         ON p.area_fips = c.geo_id
  WHERE  c.state_fips_code = '49'      -- Utah
         AND emp_2000 IS NOT NULL
         AND emp_2018 IS NOT NULL
         AND emp_2000 > 0              -- avoid divide‑by‑zero
)
SELECT county_name,
       pct_increase
FROM   utah_only
ORDER  BY pct_increase DESC
LIMIT  1;
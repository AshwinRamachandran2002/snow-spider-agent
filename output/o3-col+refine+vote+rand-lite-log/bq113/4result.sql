-- Utah county with the largest 2000-to-2018 jump in construction employment
WITH yearly_raw AS (
  -- grab the 3rd-month construction employment for every quarter
  SELECT area_fips,
         2000 AS yr,
         month3_emplvl_23_construction AS emp
  FROM   `bigquery-public-data.bls_qcew.2000_q*`
  UNION ALL
  SELECT area_fips,
         2018 AS yr,
         month3_emplvl_23_construction AS emp
  FROM   `bigquery-public-data.bls_qcew.2018_q*`
),
yearly_avg AS (
  -- average the four quarters within each year
  SELECT area_fips,
         yr,
         AVG(emp) AS avg_emp
  FROM   yearly_raw
  WHERE  area_fips LIKE '49%'          -- Utah state FIPS = 49
  GROUP  BY area_fips, yr
),
pivot AS (
  -- put 2000 and 2018 averages on the same row
  SELECT area_fips,
         MAX(IF(yr = 2000, avg_emp, NULL)) AS avg_emp_2000,
         MAX(IF(yr = 2018, avg_emp, NULL)) AS avg_emp_2018
  FROM   yearly_avg
  GROUP  BY area_fips
),
pct_change AS (
  SELECT area_fips,
         SAFE_DIVIDE(avg_emp_2018 - avg_emp_2000, avg_emp_2000) * 100 AS pct_increase
  FROM   pivot
)
SELECT c.county_name      AS county,
       ROUND(p.pct_increase, 2) AS percentage_increase
FROM   pct_change p
JOIN   `bigquery-public-data.geo_us_boundaries.counties` c
       ON p.area_fips = c.geo_id
ORDER  BY percentage_increase DESC
LIMIT  1;
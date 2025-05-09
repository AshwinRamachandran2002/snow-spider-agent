-- Greatest % increase in average third-month construction employment
-- between 2000 and 2018 for Utah counties
WITH emp_2000 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_emp_2000
  FROM `bigquery-public-data.bls_qcew.2000_q*`
  WHERE _TABLE_SUFFIX IN ('1','2','3','4')          -- 4 quarters of 2000
    AND area_fips LIKE '49%'                       -- Utah FIPS prefix
    AND LENGTH(area_fips) = 5                      -- keep county level
  GROUP BY area_fips
),
emp_2018 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_emp_2018
  FROM `bigquery-public-data.bls_qcew.2018_q*`
  WHERE _TABLE_SUFFIX IN ('1','2','3','4')          -- 4 quarters of 2018
    AND area_fips LIKE '49%'
    AND LENGTH(area_fips) = 5
  GROUP BY area_fips
),
pct_change AS (
  SELECT
    e18.area_fips,
    SAFE_DIVIDE(e18.avg_emp_2018 - e00.avg_emp_2000,
                e00.avg_emp_2000) * 100 AS pct_increase
  FROM emp_2000 e00
  JOIN emp_2018 e18 USING (area_fips)
)
SELECT
  c.county_name,
  pct.area_fips,
  ROUND(pct.pct_increase, 2) AS pct_increase
FROM pct_change pct
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.geo_id = pct.area_fips
ORDER BY pct_increase DESC
LIMIT 1;
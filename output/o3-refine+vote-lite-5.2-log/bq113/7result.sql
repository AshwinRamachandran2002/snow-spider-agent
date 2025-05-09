WITH yr2000 AS (
  SELECT
    area_fips AS county_fips,
    AVG(month3_emplvl_23_construction) AS avg_emp_2000
  FROM `bigquery-public-data.bls_qcew.2000_q*`
  WHERE area_fips LIKE '49%'            -- Utah FIPS prefix
    AND LENGTH(area_fips)=5             -- keep county–level rows
    AND month3_emplvl_23_construction IS NOT NULL
  GROUP BY area_fips
),
yr2018 AS (
  SELECT
    area_fips AS county_fips,
    AVG(month3_emplvl_23_construction) AS avg_emp_2018
  FROM `bigquery-public-data.bls_qcew.2018_q*`
  WHERE area_fips LIKE '49%'
    AND LENGTH(area_fips)=5
    AND month3_emplvl_23_construction IS NOT NULL
  GROUP BY area_fips
),
pct_change AS (
  SELECT
    c.county_name,
    ((e.avg_emp_2018 - o.avg_emp_2000) / o.avg_emp_2000) * 100 AS pct_increase
  FROM yr2000 o
  JOIN yr2018 e USING (county_fips)
  JOIN `bigquery-public-data.geo_us_boundaries.counties` c
      ON c.county_fips_code = o.county_fips
  WHERE o.avg_emp_2000 > 0                      -- avoid division by zero
)
SELECT
  county_name,
  ROUND(pct_increase,2) AS percentage_increase
FROM pct_change
ORDER BY pct_increase DESC
LIMIT 1;
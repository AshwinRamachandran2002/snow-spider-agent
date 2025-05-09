WITH base_2000 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS emp_2000
  FROM `bigquery-public-data.bls_qcew.2000_q*`
  WHERE area_fips LIKE '49%'                -- Utah state‑FIPS = 49
    AND month3_emplvl_23_construction IS NOT NULL
  GROUP BY area_fips
),
base_2018 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS emp_2018
  FROM `bigquery-public-data.bls_qcew.2018_q*`
  WHERE area_fips LIKE '49%'                -- Utah counties
    AND month3_emplvl_23_construction IS NOT NULL
  GROUP BY area_fips
),
pct_change AS (
  SELECT
    b2000.area_fips,
    b2000.emp_2000,
    b2018.emp_2018,
    (b2018.emp_2018 - b2000.emp_2000) / b2000.emp_2000 * 100 AS pct_increase
  FROM base_2000 b2000
  JOIN base_2018 b2018 USING (area_fips)
  WHERE b2000.emp_2000 > 0                 -- avoid divide‑by‑zero
)
SELECT
  c.county_name AS county,
  ROUND(p.pct_increase, 2) AS percentage_increase
FROM pct_change p
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.geo_id = p.area_fips
ORDER BY p.pct_increase DESC
LIMIT 1;
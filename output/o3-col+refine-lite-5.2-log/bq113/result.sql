-- Utah county with the largest 2000‑to‑2018 jump in month‑3 construction employment
WITH base AS (
  SELECT
    area_fips,
    -- derive the year from the table suffix
    CASE 
      WHEN _TABLE_SUFFIX LIKE '2000_%' THEN 2000 
      WHEN _TABLE_SUFFIX LIKE '2018_%' THEN 2018 
    END AS yr,
    month3_emplvl_23_construction AS empl
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('2000_q1','2000_q2','2000_q3','2000_q4',
                          '2018_q1','2018_q2','2018_q3','2018_q4')
    AND LEFT(area_fips,2) = '49'        -- Utah FIPS prefix
    AND LENGTH(area_fips) = 5           -- keep only county rows
),
yr_avg AS (
  SELECT area_fips, yr, AVG(empl) AS avg_empl
  FROM base
  GROUP BY area_fips, yr
),
pivot AS (
  SELECT
    area_fips,
    MAX(IF(yr = 2000, avg_empl, NULL)) AS avg_2000,
    MAX(IF(yr = 2018, avg_empl, NULL)) AS avg_2018
  FROM yr_avg
  GROUP BY area_fips
  HAVING avg_2000 IS NOT NULL AND avg_2018 IS NOT NULL
),
growth AS (
  SELECT
    area_fips,
    avg_2000,
    avg_2018,
    SAFE_DIVIDE(avg_2018 - avg_2000, avg_2000) * 100 AS pct_change
  FROM pivot
)
SELECT
  c.county_name,
  ROUND(g.pct_change, 2) AS pct_change
FROM growth g
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.county_fips_code = g.area_fips
ORDER BY pct_change DESC
LIMIT 1;
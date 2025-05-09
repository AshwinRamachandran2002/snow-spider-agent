/*  County in Utah with the greatest percentage increase in
    Construction employment from 2000 to 2018                  */

WITH quarter_data AS (
  -- Construction employment for the 3rd month of each quarter
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX,1,4) AS INT64) AS year,   -- 4‑digit year
    area_fips,                                         -- county FIPS
    month3_emplvl_23_construction                     AS empl
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('2000_q1','2000_q2','2000_q3','2000_q4',
                          '2018_q1','2018_q2','2018_q3','2018_q4')
    AND SUBSTR(area_fips,1,2) = '49'                  -- Utah (state‑FIPS 49)
),
annual_avg AS (
  -- average the third‑month employment across the four quarters
  SELECT
    year,
    area_fips,
    AVG(empl) AS avg_empl
  FROM quarter_data
  GROUP BY year, area_fips
),
pivot AS (
  -- 2000 vs 2018 and percentage change
  SELECT
    y2000.area_fips,
    y2000.avg_empl AS emp_2000,
    y2018.avg_empl AS emp_2018,
    SAFE_DIVIDE(y2018.avg_empl - y2000.avg_empl, y2000.avg_empl) * 100 AS pct_change
  FROM (SELECT * FROM annual_avg WHERE year = 2000) y2000
  JOIN (SELECT * FROM annual_avg WHERE year = 2018) y2018
    USING (area_fips)
),
max_change AS (
  SELECT *
  FROM pivot
  ORDER BY pct_change DESC
  LIMIT 1
)
SELECT
  c.county_name                     AS county,
  ROUND(m.pct_change, 2)            AS percentage_increase
FROM max_change m
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.geo_id = m.area_fips;
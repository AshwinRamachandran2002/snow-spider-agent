-- percentage growth of average weekly wages (all industries) in Allegheny County, PA
-- versus CPI‑U (all items, U.S. city average) between 1998 and 2017
WITH wages AS (
  -- pull the four quarterly QCEW files for 1998 and 2017 and
  -- average the weekly‐wage figure across the quarters
  SELECT
    CAST(REGEXP_REPLACE(_TABLE_SUFFIX,r'_q[1-4]','') AS INT64) AS year,
    AVG(avg_wkly_wage_10_total_all_industries)            AS avg_wkly_wage
  FROM  `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('1998_q1','1998_q2','1998_q3','1998_q4',
                          '2017_q1','2017_q2','2017_q3','2017_q4')
    AND area_fips = '42003'       -- Allegheny County, PA
  GROUP BY year
),
cpi AS (
  -- average the monthly CPI values within each year
  SELECT
    year,
    AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'   -- CPI‑U, all items, seasonally adjusted
    AND year IN (1998,2017)
  GROUP BY year
),
joined AS (
  SELECT
    w.year,
    w.avg_wkly_wage,
    c.avg_cpi
  FROM wages w
  JOIN cpi   c USING (year)
)
SELECT
  ROUND( 100 * (MAX(CASE WHEN year = 2017 THEN avg_wkly_wage END) -
                MAX(CASE WHEN year = 1998 THEN avg_wkly_wage END))
        /  MAX(CASE WHEN year = 1998 THEN avg_wkly_wage END), 2) AS wage_growth_pct,
  ROUND( 100 * (MAX(CASE WHEN year = 2017 THEN avg_cpi END) -
                MAX(CASE WHEN year = 1998 THEN avg_cpi END))
        /  MAX(CASE WHEN year = 1998 THEN avg_cpi END), 2)       AS cpi_growth_pct
FROM joined;
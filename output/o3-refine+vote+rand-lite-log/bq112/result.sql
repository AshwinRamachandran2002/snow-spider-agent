-- Percentage growth (1998‑2017) of average annual wages (all industries) in
-- Allegheny County, PA versus CPI‑U “All items” inflation.
WITH wages_qtr AS (   -- quarterly data for Allegheny County (area_fips 42003)
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX,1,4) AS INT64) AS year,
    avg_wkly_wage_10_total_all_industries          AS wkly_wage
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('1998_q1','1998_q2','1998_q3','1998_q4',
                          '2017_q1','2017_q2','2017_q3','2017_q4')
    AND area_fips = '42003'
),
wages_yr AS (         -- average weekly → average annual wage
  SELECT
    year,
    AVG(wkly_wage) * 52 AS avg_annual_wage
  FROM wages_qtr
  GROUP BY year
),
cpi_yr AS (           -- annual average CPI‑U (all items, seasonally adjusted)
  SELECT
    year,
    AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'
    AND year IN (1998,2017)
  GROUP BY year
),
base AS (
  SELECT
    (SELECT avg_annual_wage FROM wages_yr WHERE year = 1998) AS wage_1998,
    (SELECT avg_annual_wage FROM wages_yr WHERE year = 2017) AS wage_2017,
    (SELECT avg_cpi        FROM cpi_yr   WHERE year = 1998) AS cpi_1998,
    (SELECT avg_cpi        FROM cpi_yr   WHERE year = 2017) AS cpi_2017
)
SELECT
  ROUND( (wage_2017 - wage_1998) / wage_1998 * 100 , 2) AS wage_growth_pct,
  ROUND( (cpi_2017  - cpi_1998) / cpi_1998  * 100 , 2) AS cpi_growth_pct
FROM base;
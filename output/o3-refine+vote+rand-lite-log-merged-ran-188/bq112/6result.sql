-- Allegheny County (FIPS 42003) wage vs. national CPI growth, 1998-2017
WITH wages_raw AS (
  -- Quarterly average weekly wages for 1998
  SELECT 1998 AS yr,
         avg_wkly_wage_10_total_all_industries AS wage
  FROM   `bigquery-public-data.bls_qcew.1998_q*`
  WHERE  area_fips = '42003'

  UNION ALL

  -- Quarterly average weekly wages for 2017
  SELECT 2017 AS yr,
         avg_wkly_wage_10_total_all_industries
  FROM   `bigquery-public-data.bls_qcew.2017_q*`
  WHERE  area_fips = '42003'
),
wages AS (   -- calendar-year average wage
  SELECT yr,
         AVG(wage) AS avg_wage
  FROM   wages_raw
  GROUP  BY yr
),
cpi AS (     -- calendar-year average CPI-U (All items, U.S. city avg.)
  SELECT year AS yr,
         AVG(value) AS avg_cpi
  FROM   `bigquery-public-data.bls.cpi_u`
  WHERE  series_id = 'CUSR0000SA0'
    AND  year IN (1998, 2017)
  GROUP  BY year
),
numbers AS (
  SELECT
    (SELECT avg_wage FROM wages WHERE yr = 1998) AS wage_1998,
    (SELECT avg_wage FROM wages WHERE yr = 2017) AS wage_2017,
    (SELECT avg_cpi  FROM cpi   WHERE yr = 1998) AS cpi_1998,
    (SELECT avg_cpi  FROM cpi   WHERE yr = 2017) AS cpi_2017
)
SELECT
  ROUND((wage_2017 - wage_1998) / wage_1998 * 100, 2) AS wage_growth_pct,
  ROUND((cpi_2017  - cpi_1998) / cpi_1998 * 100, 2) AS cpi_growth_pct
FROM   numbers;
/*  Percentage growth in average weekly wages (all industries) for Allegheny County (FIPS 42003)
    vs. growth in CPI-U (all items, U.S. city average, seasonally adjusted)
    between 1998 and 2017                                          */

WITH wage_quarterly AS (
  -- Allegheny County (area_fips = '42003') – pull all four quarters per year
  SELECT 1998 AS year,
         avg_wkly_wage_10_total_all_industries AS wage
  FROM `bigquery-public-data.bls_qcew.1998_q*`
  WHERE area_fips = '42003'

  UNION ALL

  SELECT 2017 AS year,
         avg_wkly_wage_10_total_all_industries AS wage
  FROM `bigquery-public-data.bls_qcew.2017_q*`
  WHERE area_fips = '42003'
),
wage_yearly AS (
  SELECT year,
         AVG(wage) AS avg_weekly_wage              -- annual average of the four quarters
  FROM wage_quarterly
  GROUP BY year
),
cpi_yearly AS (
  SELECT year,
         AVG(value) AS avg_cpi                     -- annual average of 12 monthly CPI values
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'                  -- CPI-U, all items, seasonally adjusted
    AND year IN (1998, 2017)
  GROUP BY year
),
numbers AS (
  SELECT
    MAX(CASE WHEN year = 1998 THEN avg_weekly_wage END) AS wage_1998,
    MAX(CASE WHEN year = 2017 THEN avg_weekly_wage END) AS wage_2017,
    MAX(CASE WHEN year = 1998 THEN avg_cpi          END) AS cpi_1998,
    MAX(CASE WHEN year = 2017 THEN avg_cpi          END) AS cpi_2017
  FROM (
    SELECT year, avg_weekly_wage, NULL AS avg_cpi FROM wage_yearly
    UNION ALL
    SELECT year, NULL              , avg_cpi  FROM cpi_yearly
  )
)
SELECT
  ROUND((wage_2017 - wage_1998) / wage_1998 * 100, 2) AS wage_growth_pct,
  ROUND((cpi_2017  - cpi_1998 ) / cpi_1998  * 100, 2) AS cpi_growth_pct
FROM numbers;
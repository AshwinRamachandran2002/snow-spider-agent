WITH wage_quarters AS (
  SELECT 1998 AS year, avg_wkly_wage_10_total_all_industries AS wage
  FROM `bigquery-public-data.bls_qcew.1998_q1` WHERE area_fips = '42003'
  UNION ALL SELECT 1998, avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.1998_q2` WHERE area_fips = '42003'
  UNION ALL SELECT 1998, avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.1998_q3` WHERE area_fips = '42003'
  UNION ALL SELECT 1998, avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.1998_q4` WHERE area_fips = '42003'
  UNION ALL SELECT 2017, avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.2017_q1` WHERE area_fips = '42003'
  UNION ALL SELECT 2017, avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.2017_q2` WHERE area_fips = '42003'
  UNION ALL SELECT 2017, avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.2017_q3` WHERE area_fips = '42003'
  UNION ALL SELECT 2017, avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.2017_q4` WHERE area_fips = '42003'
),
wage_yearly AS (
  SELECT year, AVG(wage) AS avg_wage
  FROM wage_quarters
  GROUP BY year
),
cpi_yearly AS (
  SELECT year, AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0' AND year IN (1998, 2017)
  GROUP BY year
),
combined AS (
  SELECT
    (SELECT avg_wage FROM wage_yearly WHERE year = 1998) AS wage_1998,
    (SELECT avg_wage FROM wage_yearly WHERE year = 2017) AS wage_2017,
    (SELECT avg_cpi  FROM cpi_yearly  WHERE year = 1998) AS cpi_1998,
    (SELECT avg_cpi  FROM cpi_yearly  WHERE year = 2017) AS cpi_2017
),
growth AS (
  SELECT
    ROUND((wage_2017 - wage_1998) / wage_1998 * 100, 2) AS wage_growth_pct,
    ROUND((cpi_2017  - cpi_1998) / cpi_1998 * 100, 2) AS cpi_growth_pct
  FROM combined
)
SELECT 'wage_growth_pct' AS measure, wage_growth_pct AS percent_growth FROM growth
UNION ALL
SELECT 'cpi_growth_pct', cpi_growth_pct FROM growth;
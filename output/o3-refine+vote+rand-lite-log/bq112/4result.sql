WITH wage AS (
  -- QCEW average weekly wage for “Total, all industries” in Allegheny County (FIPS 42003)
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, 1, 4) AS INT64) AS year,
    avg_wkly_wage_10_total_all_industries AS avg_wkly_wage
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('1998_q4','2017_q4')       -- use fourth‑quarter tables as yearly proxy
    AND area_fips = '42003'                          -- Allegheny County, PA
),
wage_growth AS (
  SELECT
    MAX(CASE WHEN year = 1998 THEN avg_wkly_wage END) AS wage_1998,
    MAX(CASE WHEN year = 2017 THEN avg_wkly_wage END) AS wage_2017
  FROM wage
),
cpi AS (
  -- CPI‑U (All items, U.S. city average), unadjusted, monthly values averaged to yearly
  SELECT
    year,
    AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'        -- All items, CPI‑U
    AND seasonal_code = 'U'              -- unadjusted
    AND year IN (1998, 2017)
  GROUP BY year
),
cpi_growth AS (
  SELECT
    MAX(CASE WHEN year = 1998 THEN avg_cpi END) AS cpi_1998,
    MAX(CASE WHEN year = 2017 THEN avg_cpi END) AS cpi_2017
  FROM cpi
)
SELECT
  ROUND( (wage_2017 - wage_1998) / wage_1998 * 100, 2) AS wage_growth_percentage,
  ROUND( (cpi_2017  -  cpi_1998) /  cpi_1998 * 100, 2) AS cpi_growth_percentage
FROM wage_growth, cpi_growth;
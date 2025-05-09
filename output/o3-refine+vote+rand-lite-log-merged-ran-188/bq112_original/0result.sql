WITH wages AS (
  -- average of the 4 quarterly average‑weekly‑wage figures for each year
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, 1, 4) AS INT64) AS year,
    AVG(avg_wkly_wage_10_total_all_industries)            AS avg_weekly_wage
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX LIKE '%_q%'                               -- only qcew quarter tables
    AND CAST(SUBSTR(_TABLE_SUFFIX, 1, 4) AS INT64) IN (1998,2017)
    AND area_fips = '42003'                                     -- Allegheny County (PA)
  GROUP BY year
),
cpi AS (
  /* monthly all‑items CPI (U.S. city average, not seasonally adjusted) */
  SELECT
    year,
    AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUUR0000SA0'         -- all items, U.S. city avg., NSA
    AND year IN (1998,2017)
  GROUP BY year
),
growth AS (
  SELECT
    (SELECT avg_weekly_wage FROM wages WHERE year = 2017) AS wage_2017,
    (SELECT avg_weekly_wage FROM wages WHERE year = 1998) AS wage_1998,
    (SELECT avg_cpi        FROM cpi   WHERE year = 2017)  AS cpi_2017,
    (SELECT avg_cpi        FROM cpi   WHERE year = 1998)  AS cpi_1998
)
SELECT
  ROUND( (wage_2017 / wage_1998 - 1) * 100 , 2) AS wage_growth_pct_1998_2017,
  ROUND( (cpi_2017  /  cpi_1998 - 1) * 100 , 2) AS cpi_growth_pct_1998_2017
FROM growth;
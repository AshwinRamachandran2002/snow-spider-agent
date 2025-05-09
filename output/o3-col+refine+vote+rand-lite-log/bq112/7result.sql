WITH wages AS (
  -- quarterly QCEW wages for Allegheny County (FIPS 42003)
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX,1,4) AS INT64) AS year,
    AVG(avg_wkly_wage_10_total_all_industries)                 AS avg_wage
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('1998_q1','1998_q2','1998_q3','1998_q4',
                          '2017_q1','2017_q2','2017_q3','2017_q4')
    AND area_fips = '42003'
  GROUP BY year
),
cpi AS (
  -- monthly CPI-U (all items, seasonally adjusted) annual averages
  SELECT
    year,
    AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'      -- All items, seasonally adjusted
    AND year IN (1998, 2017)
  GROUP BY year
),
w AS (
  SELECT
    MAX(CASE WHEN year = 1998 THEN avg_wage END) AS wage_1998,
    MAX(CASE WHEN year = 2017 THEN avg_wage END) AS wage_2017
  FROM wages
),
c AS (
  SELECT
    MAX(CASE WHEN year = 1998 THEN avg_cpi END)  AS cpi_1998,
    MAX(CASE WHEN year = 2017 THEN avg_cpi END)  AS cpi_2017
  FROM cpi
)
SELECT
  ROUND( (wage_2017 - wage_1998) / wage_1998 * 100, 2) AS wage_growth_pct,
  ROUND( (cpi_2017  - cpi_1998)  / cpi_1998  * 100, 2) AS cpi_growth_pct,
  CASE
    WHEN (wage_2017 - wage_1998) / wage_1998 >= (cpi_2017 - cpi_1998) / cpi_1998
    THEN 'Yes'
    ELSE 'No'
  END AS wages_kept_pace
FROM w CROSS JOIN c;
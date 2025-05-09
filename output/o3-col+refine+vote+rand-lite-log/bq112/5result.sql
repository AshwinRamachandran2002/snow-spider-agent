-- Allegheny County (FIPS 42003) – wage vs. CPI growth, 1998-2017
WITH wage AS (
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX,1,4) AS INT64) AS yr,
    AVG(avg_wkly_wage_10_total_all_industries) AS avg_weekly_wage
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX LIKE r'(1998|2017)_q[1-4]'
    AND area_fips = '42003'                         -- Allegheny County, PA
  GROUP BY yr
),
cpi AS (
  SELECT
    year AS yr,
    AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'                   -- CPI-U, all items
    AND year IN (1998, 2017)
  GROUP BY year
)
SELECT
  'Allegheny County – 1998-2017'                             AS geography_period,
  ROUND( (MAX(CASE WHEN yr = 2017 THEN avg_weekly_wage END) -
          MAX(CASE WHEN yr = 1998 THEN avg_weekly_wage END))
        /MAX(CASE WHEN yr = 1998 THEN avg_weekly_wage END) * 100 , 2) AS wage_growth_pct,
  ROUND( (MAX(CASE WHEN yr = 2017 THEN avg_cpi END) -
          MAX(CASE WHEN yr = 1998 THEN avg_cpi END))
        /MAX(CASE WHEN yr = 1998 THEN avg_cpi END) * 100 , 2)         AS cpi_growth_pct
FROM wage
JOIN cpi USING (yr);
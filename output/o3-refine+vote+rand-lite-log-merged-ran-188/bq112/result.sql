-- Compare 1998 vs. 2017 growth of average weekly wages (all industries, Allegheny County, PA)
-- to growth of CPI-U (All items, U.S. city average, seasonally adjusted)

WITH wages AS (
  -- annual average wages = mean of the four quarterly averages
  SELECT
    1998 AS yr,
    AVG(avg_wkly_wage_10_total_all_industries) AS avg_wage
  FROM `bigquery-public-data.bls_qcew.1998_q*`
  WHERE area_fips = '42003'          -- Allegheny County, PA
  UNION ALL
  SELECT
    2017,
    AVG(avg_wkly_wage_10_total_all_industries)
  FROM `bigquery-public-data.bls_qcew.2017_q*`
  WHERE area_fips = '42003'
),
cpi AS (
  -- annual average CPI for the same years
  SELECT
    year AS yr,
    AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'    -- CPI-U, all items, seasonally adjusted
    AND year IN (1998, 2017)
  GROUP BY year
)

SELECT
  ROUND( (w17.avg_wage - w98.avg_wage) / w98.avg_wage * 100 , 2) AS wage_growth_pct,
  ROUND( (c17.avg_cpi  - c98.avg_cpi ) / c98.avg_cpi  * 100 , 2) AS cpi_growth_pct
FROM
  (SELECT avg_wage FROM wages WHERE yr = 1998) w98,
  (SELECT avg_wage FROM wages WHERE yr = 2017) w17,
  (SELECT avg_cpi  FROM cpi   WHERE yr = 1998) c98,
  (SELECT avg_cpi  FROM cpi   WHERE yr = 2017) c17;
-- Percent growth in average annual wages (all industries) for Allegheny County, PA
-- vs. percent growth in CPI‑U “All items, U.S. city average” between 1998 and 2017
WITH wage_quarters AS (
  -- grab the four quarterly files needed for each year
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX,1,4) AS INT64)               AS year,
    avg_wkly_wage_10_total_all_industries                  AS avg_weekly_wage
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('1998_q1','1998_q2','1998_q3','1998_q4',
                          '2017_q1','2017_q2','2017_q3','2017_q4')
    AND area_fips = '42003'   -- Allegheny County, Pennsylvania
),
annual_wages AS (
  -- convert to an annual average weekly wage, then to annual pay
  SELECT
    year,
    AVG(avg_weekly_wage) * 52 AS annual_wage
  FROM wage_quarters
  GROUP BY year
),
cpi_annual AS (
  -- average the 12 monthly CPI‑U values for each target year
  SELECT
    year,
    AVG(value) AS cpi_avg
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUUR0000SA0'          -- All items, U.S. city average (not seasonally adjusted)
    AND year IN (1998, 2017)
  GROUP BY year
)
SELECT
  ROUND((aw17.annual_wage - aw98.annual_wage) * 100 / aw98.annual_wage, 2) AS wages_pct_growth,
  ROUND((cpi17.cpi_avg   - cpi98.cpi_avg)   * 100 / cpi98.cpi_avg,   2) AS cpi_pct_growth
FROM (SELECT annual_wage FROM annual_wages WHERE year = 1998) aw98,
     (SELECT annual_wage FROM annual_wages WHERE year = 2017) aw17,
     (SELECT cpi_avg     FROM cpi_annual  WHERE year = 1998)  cpi98,
     (SELECT cpi_avg     FROM cpi_annual  WHERE year = 2017)  cpi17;
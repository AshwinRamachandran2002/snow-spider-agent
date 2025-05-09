-- 1)  Average annual wages (all industries) for Allegheny County, PA
-- 2)  Average annual CPI‑U “All items” index for the U.S.
-- 3)  Compare 1998 vs 2017 percentage growth for wages and CPI

WITH wages AS (
  -- Allegheny County FIPS = 42003
  SELECT 1998 AS year ,
         AVG(`avg_wkly_wage_10_total_all_industries`)*52 AS annual_wage
  FROM   `bigquery-public-data.bls_qcew.1998_q*`
  WHERE  area_fips = '42003'

  UNION ALL

  SELECT 2017 AS year ,
         AVG(`avg_wkly_wage_10_total_all_industries`)*52 AS annual_wage
  FROM   `bigquery-public-data.bls_qcew.2017_q*`
  WHERE  area_fips = '42003'
),
cpi AS (
  -- CPI‑U, All items, U.S. city average, seasonally adjusted
  SELECT year ,
         AVG(value) AS avg_cpi
  FROM   `bigquery-public-data.bls.cpi_u`
  WHERE  series_id = 'CUSR0000SA0'      -- All items (seasonally adjusted)
    AND  year IN (1998, 2017)
    AND  period LIKE 'M%'               -- monthly observations
  GROUP  BY year
),
pivot AS (
  SELECT
    MAX(CASE WHEN year = 1998 THEN annual_wage END) AS wage_1998 ,
    MAX(CASE WHEN year = 2017 THEN annual_wage END) AS wage_2017 ,
    MAX(CASE WHEN year = 1998 THEN avg_cpi     END) AS cpi_1998  ,
    MAX(CASE WHEN year = 2017 THEN avg_cpi     END) AS cpi_2017
  FROM wages
  JOIN cpi USING (year)
)
SELECT
  ROUND( (wage_2017 - wage_1998) / wage_1998 * 100 , 2) AS wage_growth_pct ,
  ROUND( (cpi_2017  - cpi_1998 ) / cpi_1998  * 100 , 2) AS cpi_growth_pct ,
  CASE
    WHEN (wage_2017 - wage_1998) / wage_1998 >=
         (cpi_2017  - cpi_1998) / cpi_1998
    THEN 'Yes' ELSE 'No'
  END AS wages_kept_pace
FROM pivot;
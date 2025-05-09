-- Average annual wage growth vs. CPI growth, 1998→2017
-- Allegheny County, PA  (FIPS / geo_id = 42003)

WITH wages AS (
  -- convert weekly wage to annual (weekly * 52)
  SELECT 1998 AS year,
         avg_wkly_wage_10_total_all_industries * 52 AS annual_wage
  FROM   `bigquery-public-data.bls_qcew.1998_q3`
  WHERE  geoid = '42003'

  UNION ALL

  SELECT 2017 AS year,
         avg_wkly_wage_10_total_all_industries * 52
  FROM   `bigquery-public-data.bls_qcew.2017_q3`
  WHERE  geoid = '42003'
),
cpi AS (
  -- annual average CPI (all items, seasonally adjusted)
  SELECT year,
         AVG(value) AS avg_cpi
  FROM   `bigquery-public-data.bls.cpi_u`
  WHERE  series_id = 'CUSR0000SA0'
    AND  year IN (1998, 2017)
  GROUP BY year
),
pivot AS (
  SELECT
    (SELECT annual_wage FROM wages WHERE year = 1998) AS wage_1998,
    (SELECT annual_wage FROM wages WHERE year = 2017) AS wage_2017,
    (SELECT avg_cpi     FROM cpi   WHERE year = 1998) AS cpi_1998,
    (SELECT avg_cpi     FROM cpi   WHERE year = 2017) AS cpi_2017
)
SELECT
  ROUND((wage_2017 - wage_1998) / wage_1998 * 100, 2) AS wage_growth_percent_1998_2017,
  ROUND((cpi_2017  - cpi_1998)  / cpi_1998  * 100, 2) AS cpi_growth_percent_1998_2017,
  CASE
    WHEN (wage_2017 - wage_1998) / wage_1998 >= (cpi_2017 - cpi_1998) / cpi_1998
    THEN 'Yes'  -- wages kept pace with or exceeded inflation
    ELSE 'No'   -- wages did NOT keep pace with inflation
  END AS wages_kept_pace_with_inflation
FROM pivot;
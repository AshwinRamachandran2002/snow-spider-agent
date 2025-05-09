-- Allegheny County (FIPS 42003) wage growth vs. CPI‑U growth, 1998‑2017
WITH wages AS (
  -- yearly average of the quarterly average‑weekly‑wage series
  SELECT
    1998 AS year,
    AVG(avg_wkly_wage_10_total_all_industries) AS avg_weekly_wage
  FROM  `bigquery-public-data.bls_qcew.1998_q*`
  WHERE geoid = '42003'

  UNION ALL

  SELECT
    2017 AS year,
    AVG(avg_wkly_wage_10_total_all_industries) AS avg_weekly_wage
  FROM  `bigquery-public-data.bls_qcew.2017_q*`
  WHERE geoid = '42003'
),
cpi AS (
  -- yearly average of the monthly CPI‑U (all items, seasonally adjusted)
  SELECT
    year,
    AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'          -- CPI‑U, all items, SA
    AND year IN (1998, 2017)
  GROUP BY year
),
base AS (
  SELECT
    MAX(CASE WHEN year = 1998 THEN avg_weekly_wage END) AS wage_1998,
    MAX(CASE WHEN year = 2017 THEN avg_weekly_wage END) AS wage_2017,
    MAX(CASE WHEN year = 1998 THEN avg_cpi          END) AS cpi_1998,
    MAX(CASE WHEN year = 2017 THEN avg_cpi          END) AS cpi_2017
  FROM wages
  FULL JOIN cpi USING (year)
)
SELECT
  ROUND((wage_2017 - wage_1998) / wage_1998 * 100, 2) AS wage_growth_pct,
  ROUND((cpi_2017  - cpi_1998 ) / cpi_1998  * 100, 2) AS cpi_growth_pct,
  CASE
    WHEN (wage_2017 - wage_1998) / wage_1998 >= (cpi_2017 - cpi_1998) / cpi_1998
      THEN 'Yes, wages kept pace with inflation.'
    ELSE 'No, wages did not keep pace with inflation.'
  END AS wages_kept_pace
FROM base;
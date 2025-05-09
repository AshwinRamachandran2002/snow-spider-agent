-- Average‑weekly wages (all industries, QCEW Q3) vs. All‑items CPI
-- Allegheny County, PA (FIPS 42003) — 1998 to 2017
WITH wages AS (
  SELECT 1998 AS yr,
         avg_wkly_wage_10_total_all_industries AS wage
  FROM `bigquery-public-data.bls_qcew.1998_q3`
  WHERE area_fips = '42003'
  UNION ALL
  SELECT 2017,
         avg_wkly_wage_10_total_all_industries
  FROM `bigquery-public-data.bls_qcew.2017_q3`
  WHERE area_fips = '42003'
),
cpi AS (
  SELECT year AS yr,
         AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'
    AND year IN (1998, 2017)
  GROUP BY year
)
SELECT
  ROUND(
    (MAX(CASE WHEN w.yr = 2017 THEN w.wage END) -
     MAX(CASE WHEN w.yr = 1998 THEN w.wage END)) /
     MAX(CASE WHEN w.yr = 1998 THEN w.wage END) * 100, 2
  ) AS pct_wage_growth,
  ROUND(
    (MAX(CASE WHEN c.yr = 2017 THEN c.avg_cpi END) -
     MAX(CASE WHEN c.yr = 1998 THEN c.avg_cpi END)) /
     MAX(CASE WHEN c.yr = 1998 THEN c.avg_cpi END) * 100, 2
  ) AS pct_cpi_growth,
  CASE
    WHEN (MAX(CASE WHEN w.yr = 2017 THEN w.wage END) -
          MAX(CASE WHEN w.yr = 1998 THEN w.wage END)) /
         MAX(CASE WHEN w.yr = 1998 THEN w.wage END)
       >=
         (MAX(CASE WHEN c.yr = 2017 THEN c.avg_cpi END) -
          MAX(CASE WHEN c.yr = 1998 THEN c.avg_cpi END)) /
         MAX(CASE WHEN c.yr = 1998 THEN c.avg_cpi END)
    THEN 'Yes'
    ELSE 'No'
  END AS wages_kept_up_with_inflation
FROM wages w
CROSS JOIN cpi c;
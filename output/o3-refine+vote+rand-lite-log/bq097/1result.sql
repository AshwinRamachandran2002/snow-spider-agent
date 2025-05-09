SELECT
  GeoName,
  MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2012 THEN Earnings_per_job_avg END) AS earnings_per_job_avg_2012,
  MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2017 THEN Earnings_per_job_avg END) AS earnings_per_job_avg_2017,
  MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2017 THEN Earnings_per_job_avg END)
  - MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2012 THEN Earnings_per_job_avg END) AS increase_amount
FROM
  `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE
  GeoName LIKE '%, MA'          -- Massachusetts regions
  AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017)
GROUP BY
  GeoName
HAVING
  earnings_per_job_avg_2012 IS NOT NULL
  AND earnings_per_job_avg_2017 IS NOT NULL
ORDER BY
  increase_amount DESC;
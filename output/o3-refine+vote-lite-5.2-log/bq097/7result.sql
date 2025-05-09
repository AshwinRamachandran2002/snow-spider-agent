SELECT
  GeoName                                           AS region,
  MAX(CASE WHEN Year = DATE '2017-01-01' THEN Earnings_per_job_avg END) AS earnings_per_job_2017,
  MAX(CASE WHEN Year = DATE '2012-01-01' THEN Earnings_per_job_avg END) AS earnings_per_job_2012,
  MAX(CASE WHEN Year = DATE '2017-01-01' THEN Earnings_per_job_avg END) -
  MAX(CASE WHEN Year = DATE '2012-01-01' THEN Earnings_per_job_avg END) AS earnings_per_job_increase
FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE GeoName LIKE '%, MA'                         -- Massachusetts regions
  AND Year IN (DATE '2012-01-01', DATE '2017-01-01')
GROUP BY GeoName
HAVING earnings_per_job_2012 IS NOT NULL           -- keep regions with data for both years
ORDER BY earnings_per_job_increase DESC;
-- Increase in average earnings per job (2017 − 2012) for every Massachusetts county
SELECT
  GeoName,
  MAX(IF(EXTRACT(YEAR FROM `Year`) = 2012, Earnings_per_job_avg, NULL)) AS avg_earnings_2012,
  MAX(IF(EXTRACT(YEAR FROM `Year`) = 2017, Earnings_per_job_avg, NULL)) AS avg_earnings_2017,
  MAX(IF(EXTRACT(YEAR FROM `Year`) = 2017, Earnings_per_job_avg, NULL))
  - MAX(IF(EXTRACT(YEAR FROM `Year`) = 2012, Earnings_per_job_avg, NULL)) AS increase_2012_to_2017
FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE GeoName LIKE '%, MA'
  AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017)
GROUP BY GeoName
ORDER BY increase_2012_to_2017 DESC;
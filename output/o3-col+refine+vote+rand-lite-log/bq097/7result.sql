SELECT
  GeoName,
  MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2017 THEN Earnings_per_job_avg END) -
  MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2012 THEN Earnings_per_job_avg END) AS increase_avg_earnings_per_job_2012_2017
FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE GeoName LIKE '%, MA'                   -- keep only Massachusetts counties
  AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017)
GROUP BY GeoName
ORDER BY increase_avg_earnings_per_job_2012_2017 DESC;
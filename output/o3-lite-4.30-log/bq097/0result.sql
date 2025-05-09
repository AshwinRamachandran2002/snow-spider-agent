SELECT
  GeoName,
  CAST(
    MAX(CASE WHEN Year = DATE '2017-01-01' THEN Earnings_per_job_avg END) -
    MAX(CASE WHEN Year = DATE '2012-01-01' THEN Earnings_per_job_avg END)
    AS NUMERIC
  ) AS avg_earnings_per_job_increase_2012_to_2017
FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE Year IN (DATE '2012-01-01', DATE '2017-01-01')
  AND GeoName LIKE '%, MA'
GROUP BY GeoName
ORDER BY avg_earnings_per_job_increase_2012_to_2017 DESC,
         GeoName;
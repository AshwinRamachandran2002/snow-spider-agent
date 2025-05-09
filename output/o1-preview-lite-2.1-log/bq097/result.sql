SELECT
  t2017.GeoName,
  ROUND(t2017.Earnings_per_job_avg - t2012.Earnings_per_job_avg, 4) AS Earnings_per_job_avg_increase
FROM
  `bigquery-public-data.sdoh_bea_cainc30.fips` t2017
JOIN
  `bigquery-public-data.sdoh_bea_cainc30.fips` t2012
ON
  t2017.GeoFIPS = t2012.GeoFIPS
WHERE
  t2017.Year = DATE '2017-01-01'
  AND t2012.Year = DATE '2012-01-01'
  AND t2017.GeoName LIKE '%, MA'
ORDER BY
  t2017.GeoName;
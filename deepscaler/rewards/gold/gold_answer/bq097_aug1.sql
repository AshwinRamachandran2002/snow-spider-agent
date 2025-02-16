-- Task: What are the average earnings per job in 2012 and 2017 for each geographic region in Massachusetts (indicated by "MA" at the end of GeoName)?
SELECT
  t2017.GeoName,
  t2012.Earnings_per_job_avg AS Earnings_per_job_avg_2012,
  t2017.Earnings_per_job_avg AS Earnings_per_job_avg_2017
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
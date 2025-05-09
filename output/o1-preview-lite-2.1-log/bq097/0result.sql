SELECT
  GeoName,
  ROUND(
    MAX(CASE WHEN Year = '2017-01-01' THEN Earnings_per_job_avg END) -
    MAX(CASE WHEN Year = '2012-01-01' THEN Earnings_per_job_avg END),
    4
  ) AS Earnings_per_job_avg_increase
FROM
  `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE
  GeoName LIKE '%MA' AND
  Year IN ('2012-01-01', '2017-01-01') AND
  Earnings_per_job_avg IS NOT NULL
GROUP BY
  GeoName
ORDER BY
  Earnings_per_job_avg_increase DESC;
SELECT
  GeoName,
  ROUND(CAST(earn_2017 - earn_2012 AS NUMERIC), 4) AS avg_earnings_per_job_increase_2012_to_2017
FROM (
  SELECT
    GeoName,
    MAX(CASE WHEN Year = DATE '2012-01-01' THEN Earnings_per_job_avg END) AS earn_2012,
    MAX(CASE WHEN Year = DATE '2017-01-01' THEN Earnings_per_job_avg END) AS earn_2017
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE GeoName LIKE '%, MA'
    AND Year IN (DATE '2012-01-01', DATE '2017-01-01')
  GROUP BY GeoName
)
WHERE earn_2012 IS NOT NULL 
  AND earn_2017 IS NOT NULL
ORDER BY avg_earnings_per_job_increase_2012_to_2017 DESC, GeoName;
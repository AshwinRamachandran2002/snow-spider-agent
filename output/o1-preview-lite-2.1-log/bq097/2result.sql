WITH earnings_2012 AS (
  SELECT `GeoName`, `Earnings_per_job_avg`
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE `Year` = '2012-01-01' AND `GeoName` LIKE '%, MA'
),
earnings_2017 AS (
  SELECT `GeoName`, `Earnings_per_job_avg`
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE `Year` = '2017-01-01' AND `GeoName` LIKE '%, MA'
)
SELECT 
  e2012.`GeoName`,
  e2017.`Earnings_per_job_avg` - e2012.`Earnings_per_job_avg` AS `Earnings_per_job_avg_increase`
FROM earnings_2012 e2012
JOIN earnings_2017 e2017
ON e2012.`GeoName` = e2017.`GeoName`
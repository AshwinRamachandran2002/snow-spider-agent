SELECT
  GeoName,
  (MAX(CASE WHEN EXTRACT(YEAR FROM Year)=2017 THEN Earnings_per_job_avg END)
   -
   MAX(CASE WHEN EXTRACT(YEAR FROM Year)=2012 THEN Earnings_per_job_avg END)
  ) AS earnings_per_job_increase_2012_2017
FROM
  `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE
  GeoName LIKE '%, MA'                          -- keep Massachusetts regions
  AND EXTRACT(YEAR FROM Year) IN (2012, 2017)   -- only needed years
GROUP BY
  GeoName
HAVING
  earnings_per_job_increase_2012_2017 IS NOT NULL
ORDER BY
  earnings_per_job_increase_2012_2017 DESC;
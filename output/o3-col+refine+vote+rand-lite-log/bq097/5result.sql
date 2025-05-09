SELECT
  GeoName AS county_ma,
  ROUND(
        AVG(CASE WHEN EXTRACT(YEAR FROM Year) = 2017 THEN earnings_per_job_avg END) -
        AVG(CASE WHEN EXTRACT(YEAR FROM Year) = 2012 THEN earnings_per_job_avg END)
       , 4) AS increase_avg_earnings_per_job_2012_2017
FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE GeoName LIKE '%, MA'
  AND EXTRACT(YEAR FROM Year) IN (2012, 2017)
  AND earnings_per_job_avg IS NOT NULL
GROUP BY GeoName
ORDER BY increase_avg_earnings_per_job_2012_2017 DESC;
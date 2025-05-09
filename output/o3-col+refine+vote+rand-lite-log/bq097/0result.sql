-- Increase in average earnings per job from 2012 to 2017 for Massachusetts counties
SELECT
  GeoName AS ma_county,
  MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2017 THEN `Earnings_per_job_avg` END) -
  MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2012 THEN `Earnings_per_job_avg` END)
    AS avg_earnings_increase_2012_2017
FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE GeoName LIKE '%, MA'
GROUP BY ma_county
ORDER BY avg_earnings_increase_2012_2017 DESC;
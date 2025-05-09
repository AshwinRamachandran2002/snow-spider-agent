-- Increase in average earnings per job (2017 – 2012) for every Massachusetts county
WITH ma_earn AS (
  SELECT
    GeoName,
    MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2012 THEN Earnings_per_job_avg END) AS earnings_2012,
    MAX(CASE WHEN EXTRACT(YEAR FROM `Year`) = 2017 THEN Earnings_per_job_avg END) AS earnings_2017
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE GeoName LIKE '%, MA'
    AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017)
  GROUP BY GeoName
)
SELECT
  GeoName,
  earnings_2012,
  earnings_2017,
  earnings_2017 - earnings_2012 AS earnings_increase
FROM ma_earn
ORDER BY earnings_increase DESC;
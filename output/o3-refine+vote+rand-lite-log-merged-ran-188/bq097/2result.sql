WITH ma_earnings AS (
  SELECT
    GeoName,
    EXTRACT(YEAR FROM `Year`) AS yr,
    Earnings_per_job_avg
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE GeoName LIKE '%, MA'      -- keep only Massachusetts geographies
    AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017)   -- needed years
)

SELECT
  GeoName,
  MAX(CASE WHEN yr = 2012 THEN Earnings_per_job_avg END) AS earnings_2012,
  MAX(CASE WHEN yr = 2017 THEN Earnings_per_job_avg END) AS earnings_2017,
  MAX(CASE WHEN yr = 2017 THEN Earnings_per_job_avg END)
  - MAX(CASE WHEN yr = 2012 THEN Earnings_per_job_avg END) AS earnings_increase
FROM ma_earnings
GROUP BY GeoName
ORDER BY earnings_increase DESC;
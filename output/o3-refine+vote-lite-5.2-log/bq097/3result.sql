WITH ma_earnings AS (
  SELECT
    GeoFIPS,
    GeoName,
    EXTRACT(YEAR FROM `Year`) AS yr,
    Earnings_per_job_avg
  FROM
    `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE
    GeoName LIKE '%, MA'                   -- Massachusetts regions
    AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017)   -- years of interest
)

SELECT
  GeoFIPS,
  GeoName,
  MAX(CASE WHEN yr = 2017 THEN Earnings_per_job_avg END) -
  MAX(CASE WHEN yr = 2012 THEN Earnings_per_job_avg END) AS earnings_per_job_increase_2012_2017
FROM
  ma_earnings
GROUP BY
  GeoFIPS,
  GeoName
HAVING
  earnings_per_job_increase_2012_2017 IS NOT NULL     -- keep regions with data for both years
ORDER BY
  earnings_per_job_increase_2012_2017 DESC;
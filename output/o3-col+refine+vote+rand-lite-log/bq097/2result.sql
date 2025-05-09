WITH ma_earnings AS (
  SELECT
    GeoName,
    EXTRACT(YEAR FROM `Year`) AS yr,
    Earnings_per_job_avg AS earnings
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE GeoName LIKE '%, MA'
    AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017)
),
pivot AS (
  SELECT
    GeoName,
    MAX(CASE WHEN yr = 2012 THEN earnings END) AS earnings_2012,
    MAX(CASE WHEN yr = 2017 THEN earnings END) AS earnings_2017
  FROM ma_earnings
  GROUP BY GeoName
)
SELECT
  GeoName,
  earnings_2017 - earnings_2012 AS increase_2012_2017
FROM pivot
ORDER BY increase_2012_2017 DESC;
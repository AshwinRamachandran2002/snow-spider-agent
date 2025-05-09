-- Increase in average earnings‑per‑job from 2012 → 2017
WITH earnings AS (
  SELECT
    GeoName,
    EXTRACT(YEAR FROM `Year`) AS yr,
    Earnings_per_job_avg
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE GeoName LIKE '% MA'                       -- Massachusetts geographies
    AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017) -- only the two target years
)

SELECT
  GeoName                                            AS geography,
  MAX(CASE WHEN yr = 2012 THEN Earnings_per_job_avg END) AS earnings_2012,
  MAX(CASE WHEN yr = 2017 THEN Earnings_per_job_avg END) AS earnings_2017,
  MAX(CASE WHEN yr = 2017 THEN Earnings_per_job_avg END)
    - MAX(CASE WHEN yr = 2012 THEN Earnings_per_job_avg END) AS increase_2012_to_2017
FROM earnings
GROUP BY GeoName
ORDER BY increase_2012_to_2017 DESC;
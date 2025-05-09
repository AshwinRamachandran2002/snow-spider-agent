-- Average earnings‑per‑job growth (2012 → 2017) for all Massachusetts
-- geographic regions appearing in BEA CAINC30 (“… , MA” at end of GeoName)
SELECT
  GeoName,
  earnings_2012,
  earnings_2017,
  earnings_2017 - earnings_2012 AS earnings_per_job_increase
FROM (
  SELECT
    GeoName,
    MAX(CASE WHEN EXTRACT(YEAR FROM `Year`)=2012 THEN Earnings_per_job_avg END) AS earnings_2012,
    MAX(CASE WHEN EXTRACT(YEAR FROM `Year`)=2017 THEN Earnings_per_job_avg END) AS earnings_2017
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE GeoName LIKE '%, MA'            -- keep Massachusetts regions only
    AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017)
  GROUP BY GeoName
)
WHERE earnings_2012 IS NOT NULL
  AND earnings_2017 IS NOT NULL
  AND earnings_2017 > earnings_2012      -- increasing only
ORDER BY earnings_per_job_increase DESC;
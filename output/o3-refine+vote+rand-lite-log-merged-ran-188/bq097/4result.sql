SELECT
  GeoFIPS,
  GeoName,
  MAX(CASE WHEN EXTRACT(YEAR FROM Year) = 2012 THEN Earnings_per_job_avg END) AS earnings_2012,
  MAX(CASE WHEN EXTRACT(YEAR FROM Year) = 2017 THEN Earnings_per_job_avg END) AS earnings_2017,
  MAX(CASE WHEN EXTRACT(YEAR FROM Year) = 2017 THEN Earnings_per_job_avg END)
  - MAX(CASE WHEN EXTRACT(YEAR FROM Year) = 2012 THEN Earnings_per_job_avg END)
    AS earnings_increase
FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE GeoName LIKE '%, MA'                       -- Massachusetts geographies
  AND EXTRACT(YEAR FROM Year) IN (2012, 2017)    -- keep only needed years
GROUP BY GeoFIPS, GeoName
HAVING earnings_2012 IS NOT NULL                -- ensure both years exist
   AND earnings_2017 IS NOT NULL
ORDER BY earnings_increase DESC;
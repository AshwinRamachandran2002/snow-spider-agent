-- Increase in average earnings per job (2012 → 2017) for every Massachusetts county
SELECT
  GeoName                                   AS county,
  AVG(CASE WHEN EXTRACT(YEAR FROM Year)=2012 THEN Earnings_per_job_avg END) AS avg_earnings_2012,
  AVG(CASE WHEN EXTRACT(YEAR FROM Year)=2017 THEN Earnings_per_job_avg END) AS avg_earnings_2017,
  (AVG(CASE WHEN EXTRACT(YEAR FROM Year)=2017 THEN Earnings_per_job_avg END) -
   AVG(CASE WHEN EXTRACT(YEAR FROM Year)=2012 THEN Earnings_per_job_avg END))   AS increase_2012_to_2017
FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
WHERE GeoName LIKE '%, MA'                               -- restrict to Massachusetts counties
  AND EXTRACT(YEAR FROM Year) IN (2012, 2017)            -- only the two target years
GROUP BY GeoName
ORDER BY GeoName;
WITH yr2012 AS (
  SELECT
    GeoFIPS,
    GeoName,
    Earnings_per_job_avg AS earnings2012
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE Year = DATE '2012-01-01'
    AND GeoName LIKE '%, MA'
),
yr2017 AS (
  SELECT
    GeoFIPS,
    GeoName,
    Earnings_per_job_avg AS earnings2017
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE Year = DATE '2017-01-01'
    AND GeoName LIKE '%, MA'
)
SELECT
  y17.GeoName AS GeoName,
  (y17.earnings2017 - y12.earnings2012) AS avg_earnings_per_job_increase_2012_to_2017
FROM yr2012 AS y12
JOIN yr2017 AS y17
USING (GeoFIPS)
ORDER BY y17.GeoName;
WITH yr2012 AS (
  SELECT
    GeoName,
    Wages_and_salaries_avg AS avg12
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE GeoName LIKE '%, MA'
    AND EXTRACT(YEAR FROM `Year`) = 2012
),
yr2017 AS (
  SELECT
    GeoName,
    Wages_and_salaries_avg AS avg17
  FROM `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE GeoName LIKE '%, MA'
    AND EXTRACT(YEAR FROM `Year`) = 2017
)
SELECT
  y17.GeoName,
  ROUND(y17.avg17 - y12.avg12, 4) AS avg_earnings_increase_2012_2017
FROM yr2012 AS y12
JOIN yr2017 AS y17 USING (GeoName)
ORDER BY avg_earnings_increase_2012_2017 DESC;
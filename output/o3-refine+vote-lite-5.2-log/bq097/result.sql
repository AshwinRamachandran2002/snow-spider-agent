WITH earnings_by_year AS (
  SELECT
    GeoName,
    EXTRACT(YEAR FROM `Year`) AS yr,
    ANY_VALUE(Earnings_per_job_avg) AS earnings_per_job_avg
  FROM
    `bigquery-public-data.sdoh_bea_cainc30.fips`
  WHERE
    GeoName LIKE '%, MA'                             -- Massachusetts regions only
    AND EXTRACT(YEAR FROM `Year`) IN (2012, 2017)    -- only the two years of interest
  GROUP BY
    GeoName,
    yr
),
earn_2012 AS (
  SELECT
    GeoName,
    earnings_per_job_avg AS earn_2012
  FROM
    earnings_by_year
  WHERE
    yr = 2012
),
earn_2017 AS (
  SELECT
    GeoName,
    earnings_per_job_avg AS earn_2017
  FROM
    earnings_by_year
  WHERE
    yr = 2017
)
SELECT
  e17.GeoName,
  e17.earn_2017 - e12.earn_2012 AS earnings_increase_between_2012_and_2017
FROM
  earn_2017 e17
JOIN
  earn_2012 e12
USING (GeoName)
ORDER BY
  earnings_increase_between_2012_and_2017 DESC;
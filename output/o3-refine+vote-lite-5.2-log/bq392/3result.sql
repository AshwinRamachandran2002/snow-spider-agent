-- Top 3 October‑2009 dates with the highest average temperature
WITH daily_temps AS (
  SELECT
    CAST(`year` AS INT64) AS yr,
    CAST(`mo` AS INT64)   AS mn,
    CAST(`da` AS INT64)   AS dy,
    AVG(temp)             AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2009`
  WHERE stn = '723758'          -- station number
    AND mo  = '10'              -- October
    AND temp <> 9999.9          -- exclude missing values
  GROUP BY yr, mn, dy
)
SELECT
  FORMAT_DATE('%Y-%m-%d', DATE(yr, mn, dy)) AS date
FROM daily_temps
ORDER BY avg_temp DESC, date
LIMIT 3;
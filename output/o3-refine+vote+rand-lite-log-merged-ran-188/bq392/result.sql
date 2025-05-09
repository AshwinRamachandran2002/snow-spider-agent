WITH daily_temps AS (
  SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS dt,
    AVG(temp) AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2009`
  WHERE stn = '723758'          -- station number
    AND mo  = '10'              -- October
    AND temp <> 9999.9          -- exclude missing values
  GROUP BY dt
)
SELECT
  FORMAT_DATE('%Y-%m-%d', dt) AS date
FROM daily_temps
ORDER BY avg_temp DESC, dt
LIMIT 3;
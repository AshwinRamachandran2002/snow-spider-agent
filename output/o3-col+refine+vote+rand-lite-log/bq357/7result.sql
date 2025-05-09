-- Top-5 highest daily-average wind speeds (2005-2015) with their dates & coordinates
WITH valid_obs AS (
  SELECT
    DATE(year, month, day) AS obs_date,
    latitude,
    longitude,
    wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_*`       -- wildcard over yearly tables
  WHERE _TABLE_SUFFIX BETWEEN '2005' AND '2015'               -- keep 2005-2015 tables
    AND wind_speed IS NOT NULL
    AND NOT IS_NAN(wind_speed)                                -- exclude NaNs
),
daily_avg AS (
  SELECT
    obs_date,
    latitude,
    longitude,
    AVG(wind_speed) AS daily_avg_wind_speed
  FROM valid_obs
  GROUP BY obs_date, latitude, longitude
)
SELECT
  obs_date,
  latitude,
  longitude,
  ROUND(daily_avg_wind_speed, 2) AS daily_avg_wind_speed
FROM daily_avg
ORDER BY daily_avg_wind_speed DESC
LIMIT 5;
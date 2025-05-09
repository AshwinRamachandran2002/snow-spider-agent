-- Top-5 daily-average wind-speed locations (2005-2015)
WITH valid_winds AS (
  SELECT
    DATE(year, month, day)           AS obs_date,
    latitude,
    longitude,
    wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_*`
  WHERE _TABLE_SUFFIX BETWEEN '2005' AND '2015'      -- restrict to 2005-2015 files
    AND wind_speed IS NOT NULL                       -- remove NULLs
    AND NOT IS_NAN(wind_speed)                       -- remove NaNs
),
daily_avg AS (
  SELECT
    obs_date,
    latitude,
    longitude,
    AVG(wind_speed) AS avg_wind
  FROM valid_winds
  GROUP BY obs_date, latitude, longitude
)
SELECT
  obs_date   AS date,
  latitude,
  longitude,
  avg_wind
FROM daily_avg
ORDER BY avg_wind DESC
LIMIT 5;
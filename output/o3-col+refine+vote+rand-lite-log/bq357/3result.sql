-- Top-5 highest daily-average wind speeds (2005-2015) with coordinates and date
WITH union_data AS (
  SELECT
    DATE(`year`,`month`,`day`)           AS obs_date,
    latitude,
    longitude,
    wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_20*`
  -- keep only years 2005-2015
  WHERE _TABLE_SUFFIX BETWEEN '05' AND '15'
    -- discard missing / NaN wind-speed values
    AND wind_speed IS NOT NULL
    AND NOT IS_NAN(wind_speed)
),
daily_avg AS (
  SELECT
    latitude,
    longitude,
    obs_date,
    AVG(wind_speed)                     AS avg_wind_speed
  FROM union_data
  GROUP BY latitude, longitude, obs_date
),
ranked AS (
  SELECT
    latitude,
    longitude,
    obs_date                            AS date,
    avg_wind_speed,
    ROW_NUMBER() OVER (ORDER BY avg_wind_speed DESC) AS rn
  FROM daily_avg
)
SELECT
  latitude,
  longitude,
  date,
  avg_wind_speed
FROM ranked
WHERE rn <= 5
ORDER BY avg_wind_speed DESC;
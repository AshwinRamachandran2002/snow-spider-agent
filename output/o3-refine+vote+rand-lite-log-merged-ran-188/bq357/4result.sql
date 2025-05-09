-- Top 5 daily‑average wind‑speed records (2005‑2015) with their
-- latitude, longitude and date, using ICOADS “core” tables
SELECT
  latitude,
  longitude,
  obs_date,
  avg_wind_speed
FROM (
  SELECT
    DATE(CAST(year AS INT64),        -- build calendar date
         CAST(month AS INT64),
         CAST(day AS INT64)) AS obs_date,
    latitude,
    longitude,
    AVG(wind_speed) AS avg_wind_speed   -- daily mean at that position
  FROM `bigquery-public-data.noaa_icoads.icoads_core_20*`
  WHERE year BETWEEN 2005 AND 2015          -- requested period
    AND wind_speed IS NOT NULL              -- exclude missing values
    AND NOT IS_NAN(wind_speed)              -- guard against NaNs
  GROUP BY obs_date, latitude, longitude
)
ORDER BY avg_wind_speed DESC
LIMIT 5;
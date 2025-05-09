-- Top‑5 daily‑average wind‑speed observations (2005‑2015)
WITH all_obs AS (
  SELECT
    DATE(CAST(year AS INT64), CAST(month AS INT64), CAST(day AS INT64)) AS obs_date,
    latitude,
    longitude,
    wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_20*`
  WHERE
    -- tables for 2005‑2015 have suffixes '05' … '15'
    _TABLE_SUFFIX BETWEEN '05' AND '15'
    AND wind_speed IS NOT NULL
    AND NOT IS_NAN(wind_speed)
),
daily_site_avg AS (
  SELECT
    obs_date,
    latitude,
    longitude,
    AVG(wind_speed) AS avg_wind_speed
  FROM all_obs
  GROUP BY obs_date, latitude, longitude
)
SELECT
  obs_date   AS date,
  latitude,
  longitude,
  avg_wind_speed
FROM daily_site_avg
ORDER BY avg_wind_speed DESC
LIMIT 5;
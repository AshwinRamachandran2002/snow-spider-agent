-- Top 5 highest daily‑average wind‑speed observations (2005‑2015)
SELECT
  DATE(year, month, day)       AS obs_date,
  latitude,
  longitude,
  AVG(wind_speed)              AS daily_avg_wind_speed
FROM `bigquery-public-data.noaa_icoads.icoads_core_*`
WHERE
  SAFE_CAST(_TABLE_SUFFIX AS INT64) BETWEEN 2005 AND 2015     -- years 2005‑2015
  AND wind_speed IS NOT NULL                                   -- exclude NULLs
  AND NOT IS_NAN(wind_speed)                                   -- exclude NaNs
GROUP BY
  obs_date,
  latitude,
  longitude
ORDER BY
  daily_avg_wind_speed DESC
LIMIT 5;
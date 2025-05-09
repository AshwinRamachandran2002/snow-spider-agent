/*  Top‑5 daily average wind‑speed (2005‑2015) with coordinates  */
WITH src AS (
  SELECT
    DATE(year, month, day) AS obs_date,
    latitude,
    longitude,
    wind_speed
  FROM
    `bigquery-public-data.noaa_icoads.icoads_core_20*`
  WHERE
        -- tables for 2005‑2015 have two‑digit suffixes 05 … 15
        _TABLE_SUFFIX IN ('05','06','07','08','09','10','11','12','13','14','15')
    AND year BETWEEN 2005 AND 2015
    AND month BETWEEN 1 AND 12
    AND day   BETWEEN 1 AND 31
    AND wind_speed IS NOT NULL
    AND NOT IS_NAN(wind_speed)
),
daily_avg AS (
  SELECT
    obs_date,
    latitude,
    longitude,
    AVG(wind_speed) AS avg_wind_speed
  FROM src
  GROUP BY obs_date, latitude, longitude
)
SELECT
  latitude,
  longitude,
  obs_date AS date,
  avg_wind_speed
FROM daily_avg
ORDER BY avg_wind_speed DESC
LIMIT 5;
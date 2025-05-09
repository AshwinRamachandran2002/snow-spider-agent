-- Top-5 highest daily-average wind speeds (2005-2015) from ICOADS core files
WITH core AS (
  SELECT
    year,
    month,
    day,
    latitude,
    longitude,
    wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_*`
  WHERE
    -- keep only the yearly partitions 2005-2015
    SAFE_CAST(_TABLE_SUFFIX AS INT64) BETWEEN 2005 AND 2015
    -- discard missing wind-speed observations
    AND wind_speed IS NOT NULL
),
daily_avg AS (
  SELECT
    DATE(year, month, day)          AS obs_date,
    latitude,
    longitude,
    AVG(wind_speed)                 AS avg_wind_speed
  FROM core
  GROUP BY obs_date, latitude, longitude
)
SELECT
  obs_date,
  latitude,
  longitude,
  ROUND(avg_wind_speed, 2)          AS avg_wind_speed
FROM daily_avg
ORDER BY avg_wind_speed DESC
LIMIT 5;
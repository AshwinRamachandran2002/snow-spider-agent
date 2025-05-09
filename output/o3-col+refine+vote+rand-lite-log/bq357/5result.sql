-- Top-5 daily-average surface wind speeds (2005-2015) and the coordinates of
-- the strongest report on each of those days
WITH all_reports AS (
  SELECT
    `year`, `month`, `day`,
    latitude,
    longitude,
    wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_*`
  -- keep only the per-year tables 2005–2015
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^20(0[5-9]|1[0-5])$')
    AND wind_speed IS NOT NULL
    AND NOT IS_NAN(wind_speed)
),
daily AS (
  SELECT
    DATE(year, month, day)                                    AS obs_date,
    AVG(wind_speed)                                           AS avg_wind_ms,
    -- coordinate of the highest individual wind report that same day
    ARRAY_AGG(STRUCT(wind_speed, latitude, longitude)
              ORDER BY wind_speed DESC LIMIT 1)[OFFSET(0)].latitude  AS latitude,
    ARRAY_AGG(STRUCT(wind_speed, latitude, longitude)
              ORDER BY wind_speed DESC LIMIT 1)[OFFSET(0)].longitude AS longitude
  FROM all_reports
  GROUP BY obs_date
)
SELECT
  obs_date   AS date,
  latitude,
  longitude,
  avg_wind_ms
FROM daily
ORDER BY avg_wind_ms DESC
LIMIT 5;
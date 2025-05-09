/*  Top‑5 latitude/longitude points with the highest
    daily‑average wind speeds between 2005‑01‑01
    and 2015‑12‑31 using ICOADS “core” data.            */
WITH base AS (
  SELECT
    -- build a safe date; rows with invalid calendar
    -- combinations will become NULL and are skipped
    SAFE.PARSE_DATE(
      '%Y-%m-%d',
      FORMAT('%04d-%02d-%02d', `year`, `month`, `day`)
    )                                AS day_date,
    latitude,
    longitude,
    wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_20*`
  WHERE
        _TABLE_SUFFIX IN ('05','06','07','08','09',
                          '10','11','12','13','14','15') -- 2005‑2015 tables
    AND `year` BETWEEN 2005 AND 2015
    AND wind_speed IS NOT NULL
    AND NOT IS_NAN(wind_speed)
    AND wind_speed < 900           -- discard sentinel values
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),
daily_means AS (
  SELECT
    day_date,
    latitude,
    longitude,
    AVG(wind_speed) AS avg_wind_speed
  FROM base
  WHERE day_date IS NOT NULL
  GROUP BY day_date, latitude, longitude
)
SELECT
  latitude,
  longitude,
  day_date                       AS date,
  avg_wind_speed                 AS daily_avg_wind_speed
FROM daily_means
ORDER BY daily_avg_wind_speed DESC
LIMIT 5;
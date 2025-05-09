-- Top 5 latitude/longitude points (2005‑2015) with the highest
-- daily‑average wind speed, ignoring missing / NaN values
WITH daily_avg AS (
  SELECT
    DATE(`year`, `month`, `day`)             AS obs_date,
    `latitude`,
    `longitude`,
    AVG(`wind_speed`)                        AS avg_wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_*`
  WHERE `year` BETWEEN 2005 AND 2015
    AND `wind_speed` IS NOT NULL             -- remove NULLs
    AND NOT IS_NAN(`wind_speed`)             -- remove NaNs
    AND `latitude`  IS NOT NULL
    AND `longitude` IS NOT NULL
  GROUP BY obs_date, latitude, longitude
)

SELECT
  obs_date        AS date,
  latitude,
  longitude,
  avg_wind_speed
FROM daily_avg
ORDER BY
  avg_wind_speed DESC,
  obs_date,
  latitude,
  longitude
LIMIT 5;
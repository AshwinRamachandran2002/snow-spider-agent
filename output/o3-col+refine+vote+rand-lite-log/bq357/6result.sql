-- Top-5 daily-average wind-speed records (2005-2015)
WITH daily_means AS (
  SELECT
    /* build a calendar date */
    DATE(year, month, day)          AS obs_date,
    /* aggregate to 0.01-degree grid cells */
    ROUND(latitude , 2)             AS latitude,
    ROUND(longitude, 2)             AS longitude,
    /* daily mean of all reports in that cell */
    AVG(wind_speed)                 AS avg_daily_wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_*`
  WHERE
        _TABLE_SUFFIX BETWEEN '2005' AND '2015'   -- yearly tables to scan
    AND wind_speed IS NOT NULL                    -- exclude missing values
  GROUP BY obs_date, latitude, longitude
)

SELECT
  obs_date,
  latitude,
  longitude,
  avg_daily_wind_speed
FROM daily_means
ORDER BY avg_daily_wind_speed DESC
LIMIT 5;
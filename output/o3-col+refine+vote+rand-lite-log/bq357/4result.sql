-- Top-5 days (2005-2015) with the highest daily-average wind speed
WITH daily_wind AS (
  SELECT
    DATE(`year`, `month`, `day`)  AS obs_date,
    ROUND(AVG(latitude), 5)       AS avg_latitude,
    ROUND(AVG(longitude), 5)      AS avg_longitude,
    AVG(wind_speed)               AS avg_wind_kts
  FROM `bigquery-public-data.noaa_icoads.icoads_core_20*`
  WHERE
        `year` BETWEEN 2005 AND 2015     -- desired years
    AND wind_speed IS NOT NULL           -- exclude missing values
  GROUP BY obs_date
)

SELECT
  obs_date        AS date,
  avg_latitude    AS latitude,
  avg_longitude   AS longitude,
  avg_wind_kts    AS average_wind_speed_knots
FROM daily_wind
ORDER BY average_wind_speed_knots DESC
LIMIT 5;
-- Top 5 daily‑average wind‑speed records (2005‑2015) with their
-- latitude, longitude, and date, ignoring missing / NaN wind values
WITH per_report AS (
  SELECT
    DATE(`year`, `month`, `day`)            AS obs_date,
    latitude,
    longitude,
    wind_speed
  FROM `bigquery-public-data.noaa_icoads.icoads_core_*`
  -- keep only the yearly tables we need
  WHERE _TABLE_SUFFIX IN ('2005','2006','2007','2008','2009',
                          '2010','2011','2012','2013','2014','2015')
    AND `year` BETWEEN 2005 AND 2015
    AND wind_speed IS NOT NULL
    AND NOT IS_NAN(wind_speed)              -- exclude NaN placeholders
),

daily_avg AS (
  SELECT
    obs_date,
    latitude,
    longitude,
    AVG(wind_speed) AS avg_daily_wind_speed
  FROM per_report
  GROUP BY obs_date, latitude, longitude
)

SELECT
  obs_date,
  latitude,
  longitude,
  avg_daily_wind_speed
FROM daily_avg
ORDER BY avg_daily_wind_speed DESC
LIMIT 5;
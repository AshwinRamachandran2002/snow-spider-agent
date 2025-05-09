-- Top 5 daily‑average wind–speed records (2005‑2015) in ICOADS core data
WITH obs AS (
  SELECT
    DATE(`year`, `month`, `day`)           AS obs_date,
    latitude,
    longitude,
    wind_speed
  FROM
    `bigquery-public-data.noaa_icoads.icoads_core_20*`
  WHERE
    -- keep only 2005‑2015 yearly tables
    _TABLE_SUFFIX IN ('05','06','07','08','09','10','11','12','13','14','15')
    -- make sure the calendar fields form a valid date
    AND `year` BETWEEN 2005 AND 2015
    AND `month` BETWEEN 1 AND 12
    AND `day` BETWEEN 1 AND 31
    -- discard missing / NaN wind‑speed values
    AND wind_speed IS NOT NULL
    AND NOT IS_NAN(wind_speed)
),
daily_avg AS (
  SELECT
    obs_date,
    latitude,
    longitude,
    AVG(wind_speed) AS avg_wind_speed
  FROM obs
  GROUP BY
    obs_date, latitude, longitude
)
SELECT
  obs_date            AS date,
  latitude,
  longitude,
  avg_wind_speed
FROM
  daily_avg
ORDER BY
  avg_wind_speed DESC,
  date                -- tie–breaker
LIMIT 5;
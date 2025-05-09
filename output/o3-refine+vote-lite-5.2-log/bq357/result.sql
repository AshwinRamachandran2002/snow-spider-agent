-- Top 5 daily‑average wind‑speed events (2005‑2015) with their coordinates
SELECT
  DATE(CAST(year AS INT64), CAST(month AS INT64), CAST(day AS INT64)) AS obs_date,
  latitude,
  longitude,
  AVG(wind_speed)               AS avg_wind_speed  -- daily average at that point
FROM
  `bigquery-public-data.noaa_icoads.icoads_core_*`
WHERE
  -- scan only yearly tables 2005‑2015
  _TABLE_SUFFIX BETWEEN '2005' AND '2015'
  -- keep the same temporal window in case multi‑year tables exist
  AND year  BETWEEN 2005 AND 2015
  -- valid wind–speed values only
  AND wind_speed IS NOT NULL
  AND NOT IS_NAN(wind_speed)
GROUP BY
  obs_date, latitude, longitude
ORDER BY
  avg_wind_speed DESC
LIMIT 5;
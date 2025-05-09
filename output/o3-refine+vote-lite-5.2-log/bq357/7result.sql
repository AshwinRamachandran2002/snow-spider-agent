-- Top 5 latitude‑longitude positions & dates (2005‑2015) with the highest
-- daily average wind‑speed values, using ICOADS “core” records only.
SELECT
  obs_date,
  latitude,
  longitude,
  avg_wind_speed
FROM (
  SELECT
    DATE(year, `month`, `day`)                                    AS obs_date,
    latitude,
    longitude,
    AVG(wind_speed)                                               AS avg_wind_speed,
    ROW_NUMBER() OVER (ORDER BY AVG(wind_speed) DESC)             AS rn
  FROM
    `bigquery-public-data.noaa_icoads.icoads_core_20*`
  WHERE
        year BETWEEN 2005 AND 2015               -- required period
    AND wind_speed IS NOT NULL                   -- exclude missing values
    AND `month` IS NOT NULL AND `day` IS NOT NULL
  GROUP BY
    obs_date, latitude, longitude
)
WHERE rn <= 5
ORDER BY avg_wind_speed DESC;
/*  Weather stations within a 20‑mile (≈32 186.9 m) radius of Chappaqua, NY
    and the count of days with valid (non‑missing) mean‑temperature
    observations recorded between 2011‑01‑01 and 2020‑12‑31            */

WITH nearby_stations AS (
  SELECT
    s.usaf,
    s.wban,
    TRIM(s.name) AS station_name,
    s.lat        AS latitude,
    s.lon        AS longitude
  FROM `bigquery-public-data.noaa_gsod.stations` AS s
  WHERE s.lat IS NOT NULL
    AND s.lon IS NOT NULL
    AND ST_DWITHIN(
          ST_GEOGPOINT(s.lon, s.lat),       -- station location
          ST_GEOGPOINT(-73.764, 41.197),    -- Chappaqua, NY
          32186.9                           -- 20 miles in metres
        )
),
valid_days AS (
  SELECT
    g.stn AS usaf,
    COUNTIF(g.temp != 9999.9) AS valid_temperature_observations
  FROM `bigquery-public-data.noaa_gsod.gsod20*` AS g
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'   -- years 2011‑2020
  GROUP BY g.stn
)

SELECT
  n.usaf   AS station_usaf,
  n.wban,
  n.station_name,
  n.latitude,
  n.longitude,
  COALESCE(v.valid_temperature_observations, 0) AS valid_temperature_observations
FROM nearby_stations AS n
LEFT JOIN valid_days AS v
  ON v.usaf = n.usaf
ORDER BY valid_temperature_observations DESC;
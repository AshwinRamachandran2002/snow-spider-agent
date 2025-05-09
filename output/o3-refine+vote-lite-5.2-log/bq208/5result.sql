-- Weather stations within 20 miles (~32 186.9 m) of Chappaqua, NY
-- and the count of valid (non‑missing) daily temperature observations
-- recorded between 2011 and 2020 inclusive.
WITH near_stations AS (
  SELECT
    usaf,
    wban,
    name,
    lat,
    lon
  FROM
    `bigquery-public-data.noaa_gsod.stations`
  WHERE
    lat IS NOT NULL
    AND lon IS NOT NULL
    AND ST_DWITHIN(
          ST_GEOGPOINT(lon, lat),             -- station location
          ST_GEOGPOINT(-73.764, 41.197),      -- Chappaqua, NY
          32186.9                             -- 20 miles in metres
        )
),
valid_temps AS (
  SELECT
    stn,
    wban
  FROM
    `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE
    _TABLE_SUFFIX BETWEEN '11' AND '20'       -- years 2011‑2020
    AND temp != 9999.9                        -- exclude missing temps
)
SELECT
  ns.usaf  AS station_usaf,
  ns.wban  AS station_wban,
  TRIM(ns.name) AS station_name,
  COUNT(*) AS valid_temperature_observations_2011_2020
FROM
  near_stations AS ns
JOIN
  valid_temps  AS vt
ON
  ns.usaf = vt.stn
  AND ns.wban = vt.wban
GROUP BY
  station_usaf,
  station_wban,
  station_name
ORDER BY
  valid_temperature_observations_2011_2020 DESC;
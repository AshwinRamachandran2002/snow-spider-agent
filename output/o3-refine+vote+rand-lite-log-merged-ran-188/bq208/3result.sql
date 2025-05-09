-- Weather stations within ~20 miles (32 186.9 m) of Chappaqua, NY
-- and their count of valid temperature observations from 2011‑2020
WITH
  chappaqua AS (
    SELECT ST_GEOGPOINT(-73.764, 41.197) AS geom
  ),
  nearby_stations AS (
    SELECT
      s.usaf,
      s.wban,
      s.name,
      ROUND(s.lat, 4) AS lat,
      ROUND(s.lon, 4) AS lon
    FROM `bigquery-public-data.noaa_gsod.stations` AS s
    CROSS JOIN chappaqua
    WHERE
      s.lat IS NOT NULL
      AND s.lon IS NOT NULL
      AND ST_DWITHIN(ST_GEOGPOINT(s.lon, s.lat), geom, 32186.9)   -- 20 miles
  )

SELECT
  ns.usaf,
  ns.wban,
  ns.name        AS station_name,
  ns.lat         AS latitude,
  ns.lon         AS longitude,
  COUNT(*)       AS valid_temp_observations_2011_2020
FROM nearby_stations AS ns
JOIN `bigquery-public-data.noaa_gsod.gsod20*` AS g
  ON g.stn  = ns.usaf
 AND g.wban = ns.wban
WHERE
      CAST(_TABLE_SUFFIX AS INT64) BETWEEN 11 AND 20   -- tables 2011‑2020
  AND g.temp IS NOT NULL
  AND g.temp != 9999.9                                -- exclude missing temps
GROUP BY
  ns.usaf, ns.wban, ns.name, ns.lat, ns.lon
ORDER BY
  valid_temp_observations_2011_2020 DESC;
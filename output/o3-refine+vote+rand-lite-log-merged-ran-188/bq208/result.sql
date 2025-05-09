-- Weather stations within 20 miles (~32 186.88 m) of Chappaqua, NY
-- and the count of valid daily temperature observations (2011‑2020)
WITH
params AS (
  SELECT
    ST_GEOGPOINT(-73.764 , 41.197)            AS target_pt ,     -- Chappaqua
    20 * 1609.344                             AS radius_m         -- 20 miles in metres
),
nearby_stations AS (
  SELECT
    s.usaf ,
    s.wban ,
    TRIM(s.name)                AS station_name ,
    s.lat ,
    s.lon
  FROM `bigquery-public-data.noaa_gsod.stations` AS s
  CROSS JOIN params
  WHERE s.lat IS NOT NULL
    AND s.lon IS NOT NULL
    AND ST_DWITHIN(
          ST_GEOGPOINT(s.lon , s.lat) ,
          params.target_pt ,
          params.radius_m
        )
)
SELECT
  ns.usaf ,
  ns.wban ,
  ns.station_name ,
  ns.lat ,
  ns.lon ,
  COUNT(*)                     AS valid_temp_observations_2011_2020
FROM nearby_stations AS ns
JOIN `bigquery-public-data.noaa_gsod.gsod*`            AS g
  ON  ns.usaf = g.stn
  AND ns.wban = g.wban
WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'          -- years 2011‑2020
  AND g.temp <> 9999.9                                 -- exclude missing temps
GROUP BY
  ns.usaf ,
  ns.wban ,
  ns.station_name ,
  ns.lat ,
  ns.lon
ORDER BY
  valid_temp_observations_2011_2020 DESC ,
  ns.usaf ,
  ns.wban;
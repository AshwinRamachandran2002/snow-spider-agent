-- Weather stations ≤ 20 miles from Chappaqua, NY (41.197 N, -73.764 W)
-- together with the count of days that contain a **valid** temperature
-- reading in the GSOD daily summary files (2011-2020).

WITH near_stations AS (                          -- 1️⃣ stations in 20-mile radius
  SELECT
    usaf       AS station_usaf,
    wban       AS station_wban,
    TRIM(name) AS station_name,
    state,
    lat,
    lon,
    ROUND(
      ST_DISTANCE(                               -- metres ➜ miles
        ST_GEOGPOINT(lon, lat),
        ST_GEOGPOINT(-73.764, 41.197)
      ) / 1609.34 , 2) AS distance_miles
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE ST_DWITHIN(
          ST_GEOGPOINT(lon, lat),
          ST_GEOGPOINT(-73.764, 41.197),
          32187                                   -- 20 miles ≈ 32 187 m
        )
),
valid_temp_days AS (                             -- 2️⃣ count valid-temp days 2011-2020
  SELECT
    stn  AS station_usaf,
    wban AS station_wban,
    COUNT(*) AS valid_observations_2011_2020
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '11' AND '20'       -- years 2011-2020
    AND temp <> 9999.9                            -- discard missing temperature
  GROUP BY station_usaf, station_wban
)

SELECT
  n.station_name,
  n.state,
  n.lat,
  n.lon,
  n.distance_miles,
  v.valid_observations_2011_2020
FROM near_stations AS n
LEFT JOIN valid_temp_days AS v
  ON  n.station_usaf = v.station_usaf
  AND n.station_wban = v.station_wban
ORDER BY n.distance_miles;
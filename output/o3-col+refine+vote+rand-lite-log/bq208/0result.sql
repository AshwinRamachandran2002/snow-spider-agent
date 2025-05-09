/*  Weather stations within 20 miles of Chappaqua, NY (41.197 N, -73.764 W)
    and the number of valid temperature observations (2011-2020).            */

WITH near_stations AS (
  SELECT
    usaf,
    wban,
    name                                             AS station_name,
    lat,
    lon,
    ROUND(
      ST_DISTANCE(
        ST_GEOGPOINT(lon, lat),                      -- station location
        ST_GEOGPOINT(-73.764, 41.197)                -- Chappaqua, NY
      ) / 1609.34,                                   -- convert m → miles
      2
    )                                                AS miles_away
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE lat IS NOT NULL
    AND lon IS NOT NULL
    AND ST_DWITHIN(                                  -- filter to 20-mile radius
          ST_GEOGPOINT(lon, lat),
          ST_GEOGPOINT(-73.764, 41.197),
          20 * 1609.34                              -- 20 miles in meters
        )
),

temp_counts AS (                                    -- 2011-2020 valid temps
  SELECT
    stn   AS usaf,
    wban,
    COUNT(*) AS valid_temperature_obs_2011_2020
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'     -- years 2011-2020 only
    AND temp < 9999.9                               -- exclude missing temps
  GROUP BY usaf, wban
)

SELECT
  n.usaf,
  n.wban,
  n.station_name,
  n.lat,
  n.lon,
  n.miles_away,
  COALESCE(t.valid_temperature_obs_2011_2020, 0)    AS valid_temperature_obs_2011_2020
FROM near_stations AS n
LEFT JOIN temp_counts AS t
USING (usaf, wban)
ORDER BY n.miles_away;
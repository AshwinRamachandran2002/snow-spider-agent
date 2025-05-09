-- weather stations within 20 miles (~32 186.88 m) of Chappaqua, NY
-- and the count of daily temperature records with valid data
-- for calendar years 2011–2020 (gsod2011 … gsod2020)

WITH stations_nearby AS (
  SELECT
    CONCAT(usaf, '-', wban)                         AS station_key,
    TRIM(name)                                      AS station_name,
    lat,
    lon,
    ST_Distance(
      ST_GeogPoint(lon, lat),
      ST_GeogPoint(-73.764, 41.197)
    ) / 1609.344                                    AS distance_miles    -- convert to miles
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE lat IS NOT NULL
    AND lon IS NOT NULL
    AND lat != 0
    AND lon != 0
    AND ST_DWITHIN(
          ST_GeogPoint(lon, lat),
          ST_GeogPoint(-73.764, 41.197),
          32186.88                                 -- 20 miles in metres
        )
),
temp_counts AS (
  SELECT
    CONCAT(stn, '-', wban) AS station_key,
    COUNT(*)              AS valid_temp_observations
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '11' AND '20'        -- tables 2011‑2020
    AND temp != 9999.9                             -- exclude missing / invalid temps
  GROUP BY station_key
)

SELECT
  s.station_key,
  s.station_name,
  s.lat   AS latitude,
  s.lon   AS longitude,
  ROUND(s.distance_miles, 2)    AS distance_miles,
  COALESCE(t.valid_temp_observations, 0) AS valid_temp_observations_2011_2020
FROM stations_nearby s
LEFT JOIN temp_counts t
  USING (station_key)
ORDER BY distance_miles;
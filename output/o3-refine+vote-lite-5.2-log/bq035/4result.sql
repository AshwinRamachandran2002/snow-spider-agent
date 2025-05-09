/*  Total distance traveled by each bike (straight‑line, Haversine)          */
/*  Result is returned in kilometers, four‑decimal precision                */

WITH stations AS (
  SELECT
    station_id,
    latitude,
    longitude
  FROM
    `bigquery-public-data.san_francisco.bikeshare_stations`
),
trip_distances AS (
  SELECT
    t.bike_number,
    /* great‑circle distance between start & end stations, in metres */
    ST_DISTANCE(
      ST_GEOGPOINT(s_start.longitude, s_start.latitude),
      ST_GEOGPOINT(s_end.longitude,   s_end.latitude)
    ) AS distance_meters
  FROM
    `bigquery-public-data.san_francisco.bikeshare_trips` AS t
  JOIN
    stations AS s_start
  ON
    t.start_station_id = s_start.station_id
  JOIN
    stations AS s_end
  ON
    t.end_station_id   = s_end.station_id
  /* exclude rows with missing coordinates */
  WHERE
    s_start.latitude  IS NOT NULL
    AND s_start.longitude IS NOT NULL
    AND s_end.latitude IS NOT NULL
    AND s_end.longitude IS NOT NULL
)

SELECT
  bike_number,
  ROUND(SUM(distance_meters) / 1000, 4) AS total_distance_km
FROM
  trip_distances
GROUP BY
  bike_number
ORDER BY
  total_distance_km DESC;
-- Total distance (in kilometers) travelled by every bike in the SF Bay Area
WITH station_coords AS (
  SELECT
    station_id,
    latitude,
    longitude
  FROM `bigquery-public-data.san_francisco.bikeshare_stations`
),

trip_distances AS (
  SELECT
    t.bike_number,

    /* great‑circle (Haversine) distance between start & end stations */
    SAFE_MULTIPLY(
      6371,   -- Earth radius in km
      ACOS(
        LEAST(1,
          GREATEST(-1,
            COS(s.latitude  * 0.017453292519943295) * COS(e.latitude * 0.017453292519943295) *
            COS((e.longitude - s.longitude) * 0.017453292519943295) +
            SIN(s.latitude  * 0.017453292519943295) * SIN(e.latitude * 0.017453292519943295)
          )
        )
      )
    ) AS trip_distance_km
  FROM `bigquery-public-data.san_francisco.bikeshare_trips` AS t
  JOIN station_coords AS s
    ON t.start_station_id = s.station_id
  JOIN station_coords AS e
    ON t.end_station_id   = e.station_id
  WHERE s.latitude  IS NOT NULL
    AND e.latitude  IS NOT NULL
)

SELECT
  bike_number,
  ROUND(SUM(trip_distance_km), 4) AS total_distance_km
FROM trip_distances
GROUP BY bike_number
ORDER BY total_distance_km DESC;
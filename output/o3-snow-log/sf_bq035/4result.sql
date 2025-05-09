/*  Total distance (in kilometers) travelled by every bike.
    – Distance for each trip is computed with the haversine formula
      using the coordinates of the trip’s start- and end-stations.
    – Results are summed per bike_number.  */

WITH trip_points AS (          -- add coordinates to every trip
    SELECT
        t."bike_number",
        ss."latitude"  AS start_lat,
        ss."longitude" AS start_lon,
        es."latitude"  AS end_lat,
        es."longitude" AS end_lon
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS    t
    JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS ss
           ON t."start_station_id" = ss."station_id"
    JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS es
           ON t."end_station_id"   = es."station_id"
),
trip_distances AS (            -- haversine distance for each trip
    SELECT
        "bike_number",
        /* 6371 km = mean earth-radius.
           LEAST(1, …) protects ACOS from rounding errors >1 */
        6371 * ACOS(
            LEAST(1,
                  SIN(RADIANS(start_lat)) * SIN(RADIANS(end_lat)) +
                  COS(RADIANS(start_lat)) * COS(RADIANS(end_lat)) *
                  COS(RADIANS(start_lon - end_lon))
            )
        ) AS distance_km
    FROM trip_points
    WHERE start_lat IS NOT NULL
      AND start_lon IS NOT NULL
      AND end_lat   IS NOT NULL
      AND end_lon   IS NOT NULL
)

SELECT
    "bike_number",
    ROUND(SUM(distance_km), 4) AS total_distance_km
FROM trip_distances
GROUP BY "bike_number"
ORDER BY total_distance_km DESC NULLS LAST;
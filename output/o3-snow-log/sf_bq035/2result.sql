/*  Total distance (in kilometers) travelled by every bike in the
    Bay-Area Bike-Share data set.

    Haversine formula is used to compute great-circle distance
    between the start and end stations of every trip, then the
    distances are summed for each individual bike_number.
*/

WITH trip_with_coords AS (
    SELECT
        t."trip_id",
        t."bike_number",
        t."start_station_id",
        t."end_station_id",
        ss."latitude"   AS start_lat,
        ss."longitude"  AS start_lon,
        es."latitude"   AS end_lat,
        es."longitude"  AS end_lon
    FROM SAN_FRANCISCO.SAN_FRANCISCO."BIKESHARE_TRIPS"   t
    JOIN SAN_FRANCISCO.SAN_FRANCISCO."BIKESHARE_STATIONS" ss
         ON t."start_station_id" = ss."station_id"
    JOIN SAN_FRANCISCO.SAN_FRANCISCO."BIKESHARE_STATIONS" es
         ON t."end_station_id"   = es."station_id"
    WHERE ss."latitude" IS NOT NULL
      AND ss."longitude" IS NOT NULL
      AND es."latitude" IS NOT NULL
      AND es."longitude" IS NOT NULL
),

trip_distances AS (
    SELECT
        "bike_number",
        /* ---- Haversine distance in kilometres ---- */
        2 * 6371 * ASIN(
            SQRT(
                  POWER(SIN(RADIANS( (end_lat - start_lat) ) / 2), 2)
                + COS(RADIANS(start_lat))
                  * COS(RADIANS(end_lat))
                  * POWER(SIN(RADIANS( (end_lon - start_lon) ) / 2), 2)
            )
        ) AS trip_distance_km
    FROM trip_with_coords
)

SELECT
    "bike_number",
    ROUND(SUM(trip_distance_km), 4) AS total_distance_km
FROM trip_distances
GROUP BY "bike_number"
ORDER BY total_distance_km DESC NULLS LAST;
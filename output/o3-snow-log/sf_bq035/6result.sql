/*  Total distance (in kilometers) travelled by every bike
    ------------------------------------------------------
    1) Bring start & end station coordinates into each trip.
    2) Compute Haversine distance for every trip (Earth-radius = 6 371 km).
    3) Aggregate by bike_number.                                   */

WITH trips_coords AS (
    SELECT
        t."bike_number",
        s_from."latitude"  AS start_lat,
        s_from."longitude" AS start_lon,
        s_to."latitude"    AS end_lat,
        s_to."longitude"   AS end_lon
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS      t
    JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS   s_from
          ON t."start_station_id" = s_from."station_id"
    JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS   s_to
          ON t."end_station_id"   = s_to."station_id"
)

SELECT
    "bike_number",
    SUM(
        2 * 6371 *                             -- Earth radius in km
        ASIN(
            SQRT(
                POWER(SIN((RADIANS(end_lat - start_lat))/2), 2) +
                COS(RADIANS(start_lat)) * COS(RADIANS(end_lat)) *
                POWER(SIN((RADIANS(end_lon - start_lon))/2), 2)
            )
        )
    ) AS total_distance_km
FROM trips_coords
GROUP BY "bike_number"
ORDER BY total_distance_km DESC NULLS LAST;
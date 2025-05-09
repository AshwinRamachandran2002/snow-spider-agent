WITH trips AS (
    /* Bring together each ride with the coordinates of its start & end stations */
    SELECT
        t."bike_number",
        s_start."latitude"  AS start_lat,
        s_start."longitude" AS start_lon,
        s_end."latitude"    AS end_lat,
        s_end."longitude"   AS end_lon
    FROM
        SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS     t
        JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS s_start
              ON t."start_station_id" = s_start."station_id"
        JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS s_end
              ON t."end_station_id"   = s_end."station_id"
    WHERE  s_start."latitude"  IS NOT NULL
       AND s_start."longitude" IS NOT NULL
       AND s_end."latitude"    IS NOT NULL
       AND s_end."longitude"   IS NOT NULL
),
trip_distances AS (
    /* Calculate great-circle (Haversine) distance for every trip in kilometers */
    SELECT
        "bike_number",
        2 * 6371 * ASIN(
            SQRT(
                  POW(SIN((RADIANS(end_lat) - RADIANS(start_lat)) / 2), 2)
                + COS(RADIANS(start_lat)) * COS(RADIANS(end_lat))
                * POW(SIN((RADIANS(end_lon) - RADIANS(start_lon)) / 2), 2)
            )
        ) AS trip_km
    FROM trips
)
SELECT
    "bike_number",
    ROUND(SUM(trip_km), 4) AS total_distance_km
FROM trip_distances
GROUP BY "bike_number"
ORDER BY total_distance_km DESC NULLS LAST;
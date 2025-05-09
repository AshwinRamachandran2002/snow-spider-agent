WITH trip_coords AS (
    SELECT
        t."trip_id",
        t."bike_number",
        s_start."latitude"  AS start_lat,
        s_start."longitude" AS start_lon,
        s_end."latitude"    AS end_lat,
        s_end."longitude"   AS end_lon
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS     t
    JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS  s_start
         ON t."start_station_id" = s_start."station_id"
    JOIN SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS  s_end
         ON t."end_station_id"   = s_end."station_id"
    WHERE   s_start."latitude"  IS NOT NULL
        AND s_start."longitude" IS NOT NULL
        AND s_end."latitude"    IS NOT NULL
        AND s_end."longitude"   IS NOT NULL
), trip_distances AS (
    SELECT
        "bike_number",
        /* Haversine distance in kilometers */
        6371 * 2 * ASIN(
              SQRT(
                    POWER(SIN(RADIANS(end_lat - start_lat) / 2), 2)
                  + COS(RADIANS(start_lat))
                  * COS(RADIANS(end_lat))
                  * POWER(SIN(RADIANS(end_lon - start_lon) / 2), 2)
              )
        ) AS trip_km
    FROM trip_coords
)
SELECT
    "bike_number",
    ROUND(SUM(trip_km), 4) AS total_distance_km
FROM trip_distances
GROUP BY "bike_number"
ORDER BY total_distance_km DESC NULLS LAST;
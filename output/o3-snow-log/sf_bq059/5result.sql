WITH berkeley_trips AS (
    SELECT
        ST_DISTANCE(
            TO_GEOGRAPHY('POINT(' || "start_station_longitude" || ' ' || "start_station_latitude" || ')'),
            TO_GEOGRAPHY('POINT(' || "end_station_longitude"   || ' ' || "end_station_latitude"   || ')')
        )                                              AS distance_m,
        "duration_sec"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE "start_station_latitude"  BETWEEN 37.85 AND 37.90
      AND "start_station_longitude" BETWEEN -122.30 AND -122.25
      AND "end_station_latitude"    BETWEEN 37.85 AND 37.90
      AND "end_station_longitude"   BETWEEN -122.30 AND -122.25
      AND "duration_sec" > 0
),
speeds AS (
    SELECT
        distance_m / "duration_sec" AS speed_m_per_s
    FROM berkeley_trips
    WHERE distance_m > 1000          -- only consider trips longer than 1 km
)
SELECT
    ROUND(MAX(speed_m_per_s), 1) AS "highest_speed_m_per_s"
FROM speeds;
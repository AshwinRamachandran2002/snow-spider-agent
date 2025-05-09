WITH station_coords AS (   -- keep station_id as TEXT; no numeric cast
    SELECT
        "station_id"                              AS station_id_str,
        ROUND("latitude",3)                       AS lat3,
        ROUND("longitude",3)                      AS lon3
    FROM NEW_YORK.NEW_YORK.CITIBIKE_STATIONS
    WHERE "latitude" IS NOT NULL
      AND "longitude" IS NOT NULL
),

/* 2016 Citi Bike trips */
bike_2016 AS (
    SELECT
        "start_station_id"                        AS start_id,
        "end_station_id"                          AS end_id,
        "start_station_name"                      AS start_name,
        "end_station_name"                        AS end_name,
        "tripduration"                            AS duration_sec
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "starttime" >= 1451606400000000   -- 2016-01-01
      AND "starttime" <  1483228800000000   -- 2017-01-01
      AND "start_station_id" IS NOT NULL
      AND "end_station_id"   IS NOT NULL
),

/* attach rounded coords to each Citi Bike trip */
bike_with_coords AS (
    SELECT
        s1.lat3                                   AS start_lat3,
        s1.lon3                                   AS start_lon3,
        s2.lat3                                   AS end_lat3,
        s2.lon3                                   AS end_lon3,
        b.start_name,
        b.end_name,
        b.duration_sec
    FROM bike_2016 b
    JOIN station_coords s1
      ON TO_VARCHAR(b.start_id) = s1.station_id_str
    JOIN station_coords s2
      ON TO_VARCHAR(b.end_id)   = s2.station_id_str
),

/* top-20 Citi Bike routes of 2016 (by trip count) */
bike_routes AS (
    SELECT
        start_lat3, start_lon3,
        end_lat3,   end_lon3,
        start_name,
        end_name,
        COUNT(*)                        AS trip_count,
        AVG(duration_sec)               AS avg_bike_sec
    FROM bike_with_coords
    GROUP BY
        start_lat3, start_lon3, end_lat3, end_lon3,
        start_name, end_name
    ORDER BY trip_count DESC NULLS LAST
    LIMIT 20
),

/* 2016 Yellow-taxi trips with rounded coords */
taxi_2016 AS (
    SELECT
        ROUND("pickup_latitude",3)      AS start_lat3,
        ROUND("pickup_longitude",3)     AS start_lon3,
        ROUND("dropoff_latitude",3)     AS end_lat3,
        ROUND("dropoff_longitude",3)    AS end_lon3,
        ( "dropoff_datetime" - "pickup_datetime")/1000000  AS duration_sec
    FROM NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE "pickup_datetime" >= 1451606400000000
      AND "pickup_datetime" <  1483228800000000
      AND "pickup_latitude"  IS NOT NULL
      AND "pickup_longitude" IS NOT NULL
      AND "dropoff_latitude" IS NOT NULL
      AND "dropoff_longitude" IS NOT NULL
      AND "dropoff_datetime" IS NOT NULL
),

/* average taxi duration for each rounded-coord route */
taxi_routes AS (
    SELECT
        start_lat3, start_lon3, end_lat3, end_lon3,
        AVG(duration_sec)               AS avg_taxi_sec
    FROM taxi_2016
    GROUP BY start_lat3, start_lon3, end_lat3, end_lon3
),

/* top-20 bike routes that are faster than taxis */
faster_than_taxi AS (
    SELECT
        b.*,
        t.avg_taxi_sec
    FROM bike_routes b
    JOIN taxi_routes t
      ON b.start_lat3 = t.start_lat3
     AND b.start_lon3 = t.start_lon3
     AND b.end_lat3   = t.end_lat3
     AND b.end_lon3   = t.end_lon3
    WHERE b.avg_bike_sec < t.avg_taxi_sec
),

/* among those, pick the one with the LONGEST average bike duration */
chosen_route AS (
    SELECT *
    FROM faster_than_taxi
    ORDER BY avg_bike_sec DESC NULLS LAST
    LIMIT 1
)

SELECT
    start_name
FROM chosen_route;
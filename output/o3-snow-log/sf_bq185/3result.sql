WITH trips AS (   -- 2016 yellow-taxi trips plus calculated duration (minutes)
    SELECT
        "pickup_datetime",
        "dropoff_datetime",
        "passenger_count",
        "trip_distance",
        "pickup_location_id",
        "dropoff_location_id",
        ("dropoff_datetime" - "pickup_datetime") / 1000000.0 / 60.0 AS trip_minutes
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TLC_YELLOW_TRIPS_2016"
),
brooklyn_zones AS (   -- taxi-zone IDs that belong to Brooklyn
    SELECT "zone_id"
    FROM   NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM"
    WHERE  UPPER("borough") = 'BROOKLYN'
),
filtered AS (         -- apply all required filters
    SELECT trip_minutes
    FROM   trips t
    JOIN   brooklyn_zones p ON p."zone_id" = t."pickup_location_id"
    JOIN   brooklyn_zones d ON d."zone_id" = t."dropoff_location_id"
    WHERE  trip_minutes          > 0         -- positive duration
      AND  t."passenger_count"   > 3         -- more than three passengers
      AND  t."trip_distance"     >= 10       -- at least 10 miles
      AND  DATE_TRUNC('day', TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1000000))
           BETWEEN '2016-02-01'::DATE AND '2016-02-07'::DATE   -- Feb 1–7 2016 inclusive
)
SELECT ROUND(AVG(trip_minutes), 4) AS avg_trip_duration_minutes
FROM   filtered;
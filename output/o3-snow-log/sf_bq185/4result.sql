WITH brooklyn_zones AS (
    SELECT "zone_id"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM
    WHERE "borough" = 'Brooklyn'
),

filtered_trips AS (
    SELECT
        ("dropoff_datetime" - "pickup_datetime") / 60000000.0 AS trip_minutes
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016
    WHERE 
        /* 1.  Date range: 1–7 Feb 2016 (inclusive)                                   */
        TO_DATE( TO_TIMESTAMP( "pickup_datetime" / 1000000 ) ) 
            BETWEEN '2016-02-01' AND '2016-02-07'
        
        /* 2.  Pickup and drop-off both in Brooklyn                                   */
        AND "pickup_location_id"  IN (SELECT "zone_id" FROM brooklyn_zones)
        AND "dropoff_location_id" IN (SELECT "zone_id" FROM brooklyn_zones)
        
        /* 3.  Trip-level filters                                                     */
        AND "trip_distance" >= 10          -- distance ≥ 10 miles
        AND "passenger_count"  >  3        -- more than 3 passengers
        AND ("dropoff_datetime" - "pickup_datetime") > 0   -- positive duration
)

SELECT ROUND( AVG(trip_minutes), 4 ) AS "avg_trip_duration_minutes"
FROM   filtered_trips;
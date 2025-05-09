WITH trips AS (
    SELECT
        yt."pickup_datetime",
        yt."dropoff_datetime",
        yt."passenger_count",
        yt."trip_distance",
        (yt."dropoff_datetime" - yt."pickup_datetime") / 60000000.0   AS trip_minutes
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TLC_YELLOW_TRIPS_2016"    yt
    /* pickup zone must be in Brooklyn */
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM"           pz
      ON pz."zone_id" = yt."pickup_location_id"
     AND pz."borough" = 'Brooklyn'
    /* drop-off zone must be in Brooklyn */
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM"           dz
      ON dz."zone_id" = yt."dropoff_location_id"
     AND dz."borough" = 'Brooklyn'
    WHERE
          /* Trip occurred 1-Feb-2016 through 7-Feb-2016 (inclusive) */
          TO_DATE( TO_TIMESTAMP_NTZ( yt."pickup_datetime" / 1000000 ) )
          BETWEEN '2016-02-01' AND '2016-02-07'
      AND yt."dropoff_datetime" > yt."pickup_datetime"     -- positive duration
      AND yt."passenger_count"  > 3                       -- more than three passengers
      AND yt."trip_distance"    >= 10                     -- at least 10 miles
)
SELECT
    ROUND( AVG(trip_minutes) , 4 )  AS "average_trip_duration_minutes"
FROM trips;
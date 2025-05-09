WITH active_stations AS (
    SELECT "station_id"
    FROM   AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE  "status" = 'active'
),
active_trips AS (
    SELECT t."start_station_id",
           t."duration_minutes"
    FROM   AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN   active_stations s
      ON   t."start_station_id" = s."station_id"
),
station_stats AS (
    SELECT  "start_station_id"               AS "station_id",
            COUNT(*)                         AS "total_starting_trips",
            AVG("duration_minutes")          AS "avg_trip_duration_min"
    FROM    active_trips
    GROUP   BY "start_station_id"
),
ranked AS (
    SELECT  "station_id",
            "total_starting_trips",
            "avg_trip_duration_min",
            DENSE_RANK() OVER (ORDER BY "total_starting_trips" DESC) AS "rk"
    FROM    station_stats
),
overall AS (
    SELECT SUM("total_starting_trips") AS "all_active_starts"
    FROM   station_stats
)
SELECT  r."station_id",
        r."total_starting_trips",
        ROUND(r."total_starting_trips" * 100.0 / o."all_active_starts", 4) AS "start_trip_pct",
        ROUND(r."avg_trip_duration_min", 4)                                AS "avg_trip_duration_min"
FROM    ranked r
CROSS   JOIN overall o
WHERE   r."rk" <= 15
ORDER BY r."rk", r."station_id";
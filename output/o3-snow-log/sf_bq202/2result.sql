WITH trips_2018 AS (
    SELECT
        "start_station_id",
        TO_TIMESTAMP("starttime" / 1000000) AS ts
    FROM NEW_YORK_PLUS.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE YEAR(TO_TIMESTAMP("starttime" / 1000000)) = 2018
),
station_counts AS (
    SELECT 
        "start_station_id",
        COUNT(*) AS trip_cnt
    FROM trips_2018
    GROUP BY "start_station_id"
    ORDER BY trip_cnt DESC NULLS LAST
    LIMIT 1           -- station with the most trips starting in 2018
),
top_station_trips AS (
    SELECT t.ts
    FROM trips_2018 t
    JOIN station_counts s
      ON t."start_station_id" = s."start_station_id"
)
SELECT
    DAYOFWEEK(ts)  AS day_of_week,   -- numeric day (1 = Sunday, 2 = Monday, …, 7 = Saturday)
    HOUR(ts)       AS hour_of_day,   -- 0-23
    COUNT(*)       AS trips
FROM top_station_trips
GROUP BY DAYOFWEEK(ts), HOUR(ts)
ORDER BY trips DESC NULLS LAST
LIMIT 1;            -- day-hour combo with the greatest number of trips
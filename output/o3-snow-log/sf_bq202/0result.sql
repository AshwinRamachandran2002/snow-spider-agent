WITH trips_2018 AS (   -- all trips that started in 2018
    SELECT
        "start_station_id",
        TO_TIMESTAMP("starttime"/1000000) AS start_ts
    FROM NEW_YORK_PLUS.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE DATE_PART('year', TO_TIMESTAMP("starttime"/1000000)) = 2018
),
top_station AS (       -- station with the most 2018 trip starts
    SELECT
        "start_station_id",
        COUNT(*)            AS trip_cnt
    FROM trips_2018
    GROUP BY "start_station_id"
    ORDER BY trip_cnt DESC NULLS LAST
    LIMIT 1
),
station_trips AS (     -- trips that began at that top station
    SELECT
        t.start_ts
    FROM trips_2018      t
    JOIN top_station     s
      ON t."start_station_id" = s."start_station_id"
),
dow_hour_counts AS (   -- count trips by day-of-week and hour
    SELECT
        DATE_PART('dow' , start_ts) AS day_of_week,   -- 0 = Sunday … 6 = Saturday
        DATE_PART('hour', start_ts) AS hour_of_day,   -- 0-23
        COUNT(*)                   AS trips
    FROM station_trips
    GROUP BY day_of_week, hour_of_day
)
SELECT
    day_of_week,        -- numeric day of week with most trips
    hour_of_day         -- hour of day with most trips
FROM dow_hour_counts
ORDER BY trips DESC NULLS LAST
LIMIT 1;
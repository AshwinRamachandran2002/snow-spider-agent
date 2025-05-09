WITH trips_2018 AS (  -- all Citi Bike trips that started in 2018
    SELECT
        "start_station_id",
        TO_TIMESTAMP_NTZ("starttime" / 1000000) AS ts
    FROM NEW_YORK_PLUS.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE EXTRACT(year FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2018
),

top_station AS (      -- station with the most trip starts in 2018
    SELECT "start_station_id"
    FROM trips_2018
    GROUP BY "start_station_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),

station_trips AS (    -- 2018 trips that began at that top station
    SELECT ts
    FROM trips_2018
    WHERE "start_station_id" = (SELECT "start_station_id" FROM top_station)
),

top_dow AS (          -- most-popular numeric day-of-week at that station
    SELECT
        EXTRACT(dow FROM ts) AS dow_num,
        COUNT(*)              AS trip_cnt
    FROM station_trips
    GROUP BY dow_num
    ORDER BY trip_cnt DESC NULLS LAST
    LIMIT 1
),

top_hour AS (         -- most-popular hour of day at that station
    SELECT
        EXTRACT(hour FROM ts) AS hour_of_day,
        COUNT(*)              AS trip_cnt
    FROM station_trips
    GROUP BY hour_of_day
    ORDER BY trip_cnt DESC NULLS LAST
    LIMIT 1
)

SELECT
    (SELECT dow_num    FROM top_dow)  AS "TOP_DAY_OF_WEEK_NUM",
    (SELECT hour_of_day FROM top_hour) AS "TOP_HOUR_OF_DAY";
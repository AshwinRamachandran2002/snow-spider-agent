WITH trips_2018 AS (   -- all CitiBike trips that started in 2018
    SELECT 
        "start_station_id",
        TO_TIMESTAMP("starttime" / 1000000) AS start_ts
    FROM NEW_YORK_PLUS.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE DATE_PART('year', TO_TIMESTAMP("starttime" / 1000000)) = 2018
), 

station_counts AS (    -- trip count per start station in 2018
    SELECT 
        "start_station_id",
        COUNT(*) AS trip_count
    FROM trips_2018
    GROUP BY "start_station_id"
), 

top_station AS (       -- station with the most 2018 starts
    SELECT "start_station_id"
    FROM station_counts
    ORDER BY trip_count DESC NULLS LAST, "start_station_id"
    LIMIT 1
),

top_station_trips AS ( -- all 2018 trips that started at that station
    SELECT t.start_ts
    FROM trips_2018  t
    JOIN top_station s
      ON t."start_station_id" = s."start_station_id"
),

dow_counts AS (        -- count by numeric day-of-week (0-Sun … 6-Sat)
    SELECT 
        DATE_PART('dow', start_ts) AS dow,
        COUNT(*)                  AS trips
    FROM top_station_trips
    GROUP BY dow
    ORDER BY trips DESC NULLS LAST
    LIMIT 1
),

hour_counts AS (       -- count by hour of day (0-23)
    SELECT 
        DATE_PART('hour', start_ts) AS hr,
        COUNT(*)                    AS trips
    FROM top_station_trips
    GROUP BY hr
    ORDER BY trips DESC NULLS LAST
    LIMIT 1
)

SELECT 
    (SELECT dow FROM dow_counts) AS "DAY_OF_WEEK_NUMERIC",
    (SELECT hr  FROM hour_counts) AS "HOUR_OF_DAY"
;
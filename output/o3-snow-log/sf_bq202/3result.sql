WITH trips_2018 AS (
    SELECT
        "start_station_id",
        TO_TIMESTAMP("starttime" / 1000000)                                   AS ts
    FROM NEW_YORK_PLUS.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE DATE_PART('YEAR', TO_TIMESTAMP("starttime" / 1000000)) = 2018
          AND "start_station_id" IS NOT NULL
),
top_station AS (
    SELECT
        "start_station_id"
    FROM trips_2018
    GROUP BY "start_station_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
station_trips AS (
    SELECT
        DATE_PART('DOW',  ts)                         AS day_of_week,   -- 0 = Sunday … 6 = Saturday
        DATE_PART('HOUR', ts)                         AS hour_of_day,   -- 0–23
        COUNT(*)                                      AS trip_count
    FROM trips_2018
    WHERE "start_station_id" = (SELECT "start_station_id" FROM top_station)
    GROUP BY day_of_week, hour_of_day
)
SELECT
    day_of_week,
    hour_of_day
FROM station_trips
ORDER BY trip_count DESC NULLS LAST
LIMIT 1;
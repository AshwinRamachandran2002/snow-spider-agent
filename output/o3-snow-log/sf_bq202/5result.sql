WITH trips_2018 AS (
    SELECT
        "start_station_id",
        "starttime",
        TO_TIMESTAMP_NTZ("starttime" / 1000000) AS "ts"
    FROM NEW_YORK_PLUS.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE DATE_PART('year', TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2018
),
top_station AS (
    SELECT "start_station_id"
    FROM trips_2018
    GROUP BY "start_station_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
target_trips AS (
    SELECT t."ts"
    FROM trips_2018 t
    JOIN top_station s
      ON t."start_station_id" = s."start_station_id"
),
dow_hour_counts AS (
    SELECT
        DATE_PART('dayofweek', "ts")  AS "dow_num",   -- 1 = Sunday … 7 = Saturday
        DATE_PART('hour',      "ts")  AS "hour_of_day",
        COUNT(*)                        AS "trip_cnt"
    FROM target_trips
    GROUP BY
        DATE_PART('dayofweek', "ts"),
        DATE_PART('hour',      "ts")
),
ranked AS (
    SELECT
        "dow_num",
        "hour_of_day",
        "trip_cnt",
        ROW_NUMBER() OVER (ORDER BY "trip_cnt" DESC, "dow_num", "hour_of_day") AS rn
    FROM dow_hour_counts
)
SELECT
    "dow_num"      AS numeric_day_of_week,
    "hour_of_day"  AS hour_of_day
FROM ranked
WHERE rn = 1;
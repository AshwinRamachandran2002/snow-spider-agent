WITH trips_2016 AS (
    SELECT
        "start_station_id",
        TO_TIMESTAMP("starttime" / 1e6) AS "start_timestamp"
    FROM
        "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
    WHERE
        EXTRACT(year FROM TO_TIMESTAMP("starttime" / 1e6)) = 2016
),
top_station AS (
    SELECT
        "start_station_id"
    FROM
        trips_2016
    GROUP BY
        "start_station_id"
    ORDER BY
        COUNT(*) DESC NULLS LAST
    LIMIT 1
),
busiest_day_hour AS (
    SELECT
        EXTRACT(dow FROM "start_timestamp") AS "Numeric_day_of_week",
        EXTRACT(hour FROM "start_timestamp") AS "Hour_of_day",
        COUNT(*) AS "trip_count"
    FROM
        trips_2016
    WHERE
        "start_station_id" = (SELECT "start_station_id" FROM top_station)
    GROUP BY
        EXTRACT(dow FROM "start_timestamp"),
        EXTRACT(hour FROM "start_timestamp")
    ORDER BY
        "trip_count" DESC NULLS LAST
    LIMIT 1
)
SELECT
    "Numeric_day_of_week",
    "Hour_of_day"
FROM
    busiest_day_hour;
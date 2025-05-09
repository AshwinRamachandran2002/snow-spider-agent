WITH top_station AS (
    SELECT "start_station_id"
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("starttime" / 1e6)) = 2016
    GROUP BY "start_station_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
hour_day_counts AS (
    SELECT
        EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP_NTZ("starttime" / 1e6)) AS "Numeric_day_of_week",
        EXTRACT(HOUR FROM TO_TIMESTAMP_NTZ("starttime" / 1e6)) AS "Hour_of_day",
        COUNT(*) AS "trip_count"
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "start_station_id" = (SELECT "start_station_id" FROM top_station)
      AND EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("starttime" / 1e6)) = 2016
    GROUP BY "Numeric_day_of_week", "Hour_of_day"
    ORDER BY "trip_count" DESC NULLS LAST
    LIMIT 1
)
SELECT "Numeric_day_of_week", "Hour_of_day"
FROM hour_day_counts;
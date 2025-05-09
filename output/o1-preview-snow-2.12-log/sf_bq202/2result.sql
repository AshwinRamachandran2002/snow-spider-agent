WITH
top_station AS (
    SELECT "start_station_id"
    FROM "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2016
    GROUP BY "start_station_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
day_of_week_cte AS (
    SELECT
        EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) AS "day_of_week",
        COUNT(*) AS "trip_count"
    FROM "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
    WHERE "start_station_id" = (SELECT "start_station_id" FROM top_station)
        AND EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2016
    GROUP BY "day_of_week"
    ORDER BY "trip_count" DESC NULLS LAST
    LIMIT 1
),
hour_of_day_cte AS (
    SELECT
        EXTRACT(HOUR FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) AS "hour_of_day",
        COUNT(*) AS "trip_count"
    FROM "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
    WHERE "start_station_id" = (SELECT "start_station_id" FROM top_station)
        AND EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2016
    GROUP BY "hour_of_day"
    ORDER BY "trip_count" DESC NULLS LAST
    LIMIT 1
)
SELECT
    day_of_week_cte."day_of_week" AS "Numeric_day_of_week",
    hour_of_day_cte."hour_of_day" AS "Hour_of_day"
FROM day_of_week_cte, hour_of_day_cte;
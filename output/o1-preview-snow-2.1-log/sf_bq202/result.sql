WITH trip_counts AS (
    SELECT
        "start_station_id",
        COUNT(*) AS trip_count
    FROM
        "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
    WHERE
        EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2016
    GROUP BY
        "start_station_id"
    ORDER BY
        trip_count DESC NULLS LAST
    LIMIT 1
),
trip_data AS (
    SELECT
        EXTRACT(DOW FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) AS "Peak_Day_of_Week",
        EXTRACT(HOUR FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) AS "Peak_Hour_of_Day"
    FROM
        "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
    WHERE
        "start_station_id" = (SELECT "start_station_id" FROM trip_counts)
        AND EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2016
)
SELECT
    "Peak_Day_of_Week",
    "Peak_Hour_of_Day"
FROM
    trip_data
GROUP BY
    "Peak_Day_of_Week",
    "Peak_Hour_of_Day"
ORDER BY
    COUNT(*) DESC NULLS LAST
LIMIT 1;
WITH trips AS (
    SELECT 
        "starttime",
        "start_station_id"
    FROM 
        NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE 
        "starttime" BETWEEN 1451606400000000 AND 1475279999000000 -- 2016-01-01 to 2016-09-30
),
top_station AS (
    SELECT 
        "start_station_id",
        COUNT(*) AS trip_count
    FROM
        trips
    GROUP BY
        "start_station_id"
    ORDER BY
        trip_count DESC NULLS LAST
    LIMIT 1
),
peak_time AS (
    SELECT
        EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP("starttime" / 1000000)) AS "Peak_Day_of_Week",
        EXTRACT(HOUR FROM TO_TIMESTAMP("starttime" / 1000000)) AS "Peak_Hour_of_Day",
        COUNT(*) AS trip_count
    FROM
        trips
    WHERE
        "start_station_id" = (SELECT "start_station_id" FROM top_station)
    GROUP BY
        EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP("starttime" / 1000000)),
        EXTRACT(HOUR FROM TO_TIMESTAMP("starttime" / 1000000))
    ORDER BY
        trip_count DESC NULLS LAST
    LIMIT 1
)
SELECT
    "Peak_Day_of_Week",
    "Peak_Hour_of_Day"
FROM
    peak_time;
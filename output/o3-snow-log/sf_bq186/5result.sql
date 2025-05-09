WITH trip_data AS (
    SELECT
        /* derive YYYYMM key from the trip start date */
        TO_CHAR(
            DATE_TRUNC(
                'MONTH',
                TO_TIMESTAMP_NTZ("start_date" / 1000000.0)   -- microseconds → timestamp
            ),
            'YYYYMM'
        )                       AS "year_month",
        "start_date"            AS "start_ts_int",            -- keep raw start-time for ordering
        "duration_sec" / 60.0   AS "duration_min"             -- seconds → minutes
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
)

SELECT
    "year_month",
    ROUND( (ARRAY_AGG("duration_min") WITHIN GROUP (ORDER BY "start_ts_int" ASC ))[0] , 4)  AS "first_trip_duration_min",
    ROUND( (ARRAY_AGG("duration_min") WITHIN GROUP (ORDER BY "start_ts_int" DESC))[0] , 4)  AS "last_trip_duration_min",
    ROUND( MAX("duration_min"), 4)                                                         AS "highest_trip_duration_min",
    ROUND( MIN("duration_min"), 4)                                                         AS "lowest_trip_duration_min"
FROM trip_data
GROUP BY "year_month"
ORDER BY "year_month";
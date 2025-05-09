SELECT
    ym                                  AS "YYYYMM",
    ROUND( MIN_BY(duration_min,start_ts), 4) AS "first_trip_duration_min",
    ROUND( MAX_BY(duration_min,start_ts), 4) AS "last_trip_duration_min",
    ROUND( MAX(duration_min), 4)            AS "highest_trip_duration_min",
    ROUND( MIN(duration_min), 4)            AS "lowest_trip_duration_min"
FROM (
    SELECT
        TO_CHAR( TO_TIMESTAMP_LTZ("start_date" / 1000000), 'YYYYMM')      AS ym,
        "duration_sec" / 60.0                                             AS duration_min,
        TO_TIMESTAMP_LTZ("start_date" / 1000000)                          AS start_ts
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
) t
GROUP BY ym
ORDER BY ym;
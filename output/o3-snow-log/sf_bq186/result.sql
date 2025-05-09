WITH trips AS (
    SELECT
        /* build yyyymm key from the micro-second epoch in "start_date" */
        TO_CHAR( TO_TIMESTAMP( "start_date" / 1000000 ), 'YYYYMM' )          AS "YEAR_MONTH",
        "start_date"                                                        AS "START_TS",
        "duration_sec" / 60.0                                               AS "DURATION_MIN"
    FROM  SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
)

SELECT
    "YEAR_MONTH",
    MIN_BY( "DURATION_MIN", "START_TS" )  AS "FIRST_TRIP_MIN",
    MAX_BY( "DURATION_MIN", "START_TS" )  AS "LAST_TRIP_MIN",
    MAX( "DURATION_MIN" )                 AS "HIGHEST_TRIP_MIN",
    MIN( "DURATION_MIN" )                 AS "LOWEST_TRIP_MIN"
FROM trips
GROUP BY "YEAR_MONTH"
ORDER BY "YEAR_MONTH";
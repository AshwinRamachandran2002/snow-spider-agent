WITH trips AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP("start_date" / 1000000), 'YYYYMM') AS "YEAR_MONTH",
        "start_date"                                            AS "START_DATE",
        "duration_sec"                                          AS "DURATION_SEC"
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
    WHERE "start_date" IS NOT NULL
)

SELECT
    "YEAR_MONTH",
    MIN_BY("DURATION_SEC", "START_DATE") / 60.0 AS "FIRST_TRIP_DURATION_MIN",
    MAX_BY("DURATION_SEC", "START_DATE") / 60.0 AS "LAST_TRIP_DURATION_MIN",
    MAX("DURATION_SEC") / 60.0                  AS "HIGHEST_TRIP_DURATION_MIN",
    MIN("DURATION_SEC") / 60.0                  AS "LOWEST_TRIP_DURATION_MIN"
FROM trips
GROUP BY "YEAR_MONTH"
ORDER BY "YEAR_MONTH";
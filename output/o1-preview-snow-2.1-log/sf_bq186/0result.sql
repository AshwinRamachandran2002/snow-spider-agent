SELECT
    "Month",
    ROUND(MIN_BY("duration_sec", "start_date") / 60.0, 4) AS "First_trip_duration_minutes",
    ROUND(MAX_BY("duration_sec", "start_date") / 60.0, 4) AS "Last_trip_duration_minutes",
    ROUND(MAX("duration_sec") / 60.0, 4) AS "Highest_trip_duration_minutes",
    ROUND(MIN("duration_sec") / 60.0, 4) AS "Lowest_trip_duration_minutes"
FROM (
    SELECT
        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP("start_date" / 1e6)), 'YYYY-MM') AS "Month",
        "start_date",
        "duration_sec"
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
) t
GROUP BY "Month"
ORDER BY "Month";
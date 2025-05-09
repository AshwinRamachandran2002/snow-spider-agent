SELECT
    "YearMonth",
    ROUND(MIN_BY("duration_sec", "start_date") / 60.0, 4) AS "FirstTripDurationMinutes",
    ROUND(MIN_BY("duration_sec", -"start_date") / 60.0, 4) AS "LastTripDurationMinutes",
    ROUND(MAX("duration_sec") / 60.0, 4) AS "HighestTripDurationMinutes",
    ROUND(MIN("duration_sec") / 60.0, 4) AS "LowestTripDurationMinutes"
FROM (
    SELECT
        TO_CHAR(TO_TIMESTAMP_LTZ("start_date" / 1000000), 'YYYYMM') AS "YearMonth",
        "duration_sec",
        "start_date"
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
)
GROUP BY
    "YearMonth"
ORDER BY
    "YearMonth";
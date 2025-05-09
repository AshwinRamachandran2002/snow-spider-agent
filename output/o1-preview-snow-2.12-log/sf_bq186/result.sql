WITH trip_data AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_LTZ("start_date" / 1e6), 'YYYYMM') AS YearMonth,
        "trip_id",
        "start_date",
        ROUND("duration_sec" / 60.0, 4) AS duration_minutes
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
)
SELECT
    YearMonth,
    FirstTripDurationMinutes,
    LastTripDurationMinutes,
    HighestTripDurationMinutes,
    LowestTripDurationMinutes
FROM (
    SELECT
        YearMonth,
        FIRST_VALUE(duration_minutes) OVER (
            PARTITION BY YearMonth
            ORDER BY "start_date" ASC NULLS LAST
        ) AS FirstTripDurationMinutes,
        FIRST_VALUE(duration_minutes) OVER (
            PARTITION BY YearMonth
            ORDER BY "start_date" DESC NULLS LAST
        ) AS LastTripDurationMinutes,
        MAX(duration_minutes) OVER (PARTITION BY YearMonth) AS HighestTripDurationMinutes,
        MIN(duration_minutes) OVER (PARTITION BY YearMonth) AS LowestTripDurationMinutes,
        ROW_NUMBER() OVER (
            PARTITION BY YearMonth
            ORDER BY "start_date" ASC NULLS LAST
        ) AS rn
    FROM trip_data
)
WHERE rn = 1
ORDER BY YearMonth;
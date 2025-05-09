WITH Trips_Per_Month AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("start_date" / 1000000)) AS "Month",
        "start_date",
        "duration_sec"
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
),
First_Trip_Duration AS (
    SELECT
        "Month",
        "duration_sec" AS "First_trip_duration_sec"
    FROM (
        SELECT
            "Month",
            "start_date",
            "duration_sec",
            ROW_NUMBER() OVER (PARTITION BY "Month" ORDER BY "start_date" ASC NULLS LAST) AS rn
        FROM Trips_Per_Month
    )
    WHERE rn = 1
),
Last_Trip_Duration AS (
    SELECT
        "Month",
        "duration_sec" AS "Last_trip_duration_sec"
    FROM (
        SELECT
            "Month",
            "start_date",
            "duration_sec",
            ROW_NUMBER() OVER (PARTITION BY "Month" ORDER BY "start_date" DESC NULLS LAST) AS rn
        FROM Trips_Per_Month
    )
    WHERE rn = 1
),
Max_Min_Duration AS (
    SELECT
        "Month",
        MAX("duration_sec") AS "Highest_trip_duration_sec",
        MIN("duration_sec") AS "Lowest_trip_duration_sec"
    FROM Trips_Per_Month
    GROUP BY "Month"
)
SELECT
    TO_CHAR(f."Month", 'YYYY-MM') AS "Month",
    ROUND(f."First_trip_duration_sec" / 60, 4) AS "First_trip_duration_minutes",
    ROUND(l."Last_trip_duration_sec" / 60, 4) AS "Last_trip_duration_minutes",
    ROUND(m."Highest_trip_duration_sec" / 60, 4) AS "Highest_trip_duration_minutes",
    ROUND(m."Lowest_trip_duration_sec" / 60, 4) AS "Lowest_trip_duration_minutes"
FROM First_Trip_Duration f
JOIN Last_Trip_Duration l ON f."Month" = l."Month"
JOIN Max_Min_Duration m ON f."Month" = m."Month"
ORDER BY f."Month";
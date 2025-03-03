WITH trips AS (
    SELECT
        ROUND("trip_seconds" / 60.0) AS "trip_minutes",
        "fare"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE "trip_seconds" IS NOT NULL AND "fare" IS NOT NULL
        AND ROUND("trip_seconds" / 60.0) BETWEEN 1 AND 50
),
trips_with_quantiles AS (
    SELECT
        "trip_minutes",
        "fare",
        NTILE(10) OVER (ORDER BY "trip_minutes") AS quantile
    FROM trips
),
quantile_stats AS (
    SELECT
        quantile,
        MIN("trip_minutes") AS min_minutes,
        MAX("trip_minutes") AS max_minutes,
        COUNT(*) AS "Total_Number_of_Trips",
        ROUND(AVG("fare"), 4) AS "Average_Fare"
    FROM trips_with_quantiles
    GROUP BY quantile
)
SELECT
    CONCAT('Quantile ', quantile, ' (', min_minutes, '-', max_minutes, ' minutes)') AS "Trip_Duration_Minutes_Quantile",
    "Total_Number_of_Trips",
    "Average_Fare"
FROM quantile_stats
ORDER BY quantile;
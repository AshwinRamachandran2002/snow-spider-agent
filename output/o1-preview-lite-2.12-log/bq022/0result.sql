SELECT
    quantile_group AS Quantile_Group,
    MIN(trip_minutes) AS Min_Trip_Duration_Minutes,
    MAX(trip_minutes) AS Max_Trip_Duration_Minutes,
    COUNT(*) AS Total_Number_of_Trips,
    ROUND(AVG(fare), 4) AS Average_Fare
FROM (
    SELECT
        trip_minutes,
        fare,
        NTILE(6) OVER (ORDER BY trip_minutes) AS quantile_group
    FROM (
        SELECT
            ROUND(trip_seconds / 60) AS trip_minutes,
            fare
        FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
        WHERE
            trip_seconds > 0
            AND trip_seconds <= 3600
            AND fare IS NOT NULL
            AND fare > 0
    ) AS subquery
) AS grouped_data
GROUP BY quantile_group
ORDER BY quantile_group;
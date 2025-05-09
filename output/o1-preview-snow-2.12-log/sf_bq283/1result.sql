WITH station_trip_counts AS (
    SELECT
        s."station_id" AS "Station_ID",
        COUNT(t."trip_id") AS "Total_Starting_Trips",
        AVG(t."duration_minutes") AS "Average_Trip_Duration_Minutes"
    FROM
        AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s
    JOIN
        AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
            ON s."station_id" = t."start_station_id"
    WHERE
        s."status" = 'active'
    GROUP BY
        s."station_id"
),
total_active_trips AS (
    SELECT COUNT(t2."trip_id") AS total_active_trips
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t2
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s2
        ON t2."start_station_id" = s2."station_id"
    WHERE s2."status" = 'active'
),
threshold AS (
    SELECT MIN("Total_Starting_Trips") AS threshold
    FROM (
        SELECT "Total_Starting_Trips"
        FROM station_trip_counts
        ORDER BY "Total_Starting_Trips" DESC NULLS LAST
        LIMIT 15
    )
)
SELECT
    stc."Station_ID",
    stc."Total_Starting_Trips",
    ROUND((stc."Total_Starting_Trips" * 100.0) / tat.total_active_trips, 4) AS "Percentage_of_Total_Starting_Trips",
    ROUND(stc."Average_Trip_Duration_Minutes", 4) AS "Average_Trip_Duration_Minutes"
FROM station_trip_counts stc
CROSS JOIN total_active_trips tat
CROSS JOIN threshold t
WHERE stc."Total_Starting_Trips" >= t.threshold
ORDER BY stc."Total_Starting_Trips" DESC NULLS LAST;
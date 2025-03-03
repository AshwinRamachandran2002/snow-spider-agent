WITH active_trips AS (
    SELECT
        t."start_station_id" AS "Station_ID",
        COUNT(*) AS "Total_Starting_Trips",
        AVG(t."duration_minutes") AS "Average_Trip_Duration_Minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s
        ON t."start_station_id" = s."station_id"
    WHERE s."status" ILIKE 'active'
    GROUP BY t."start_station_id"
),
total_active_trips AS (
    SELECT SUM("Total_Starting_Trips") AS "Total_Active_Trips"
    FROM active_trips
),
ranked_trips AS (
    SELECT
        "Station_ID",
        "Total_Starting_Trips",
        ("Total_Starting_Trips" * 100.0) / (SELECT "Total_Active_Trips" FROM total_active_trips) AS "Percentage_of_Total_Starting_Trips",
        "Average_Trip_Duration_Minutes",
        DENSE_RANK() OVER (ORDER BY "Total_Starting_Trips" DESC NULLS LAST) AS "Rank"
    FROM active_trips
)
SELECT
    "Station_ID",
    "Total_Starting_Trips",
    ROUND("Percentage_of_Total_Starting_Trips", 4) AS "Percentage_of_Total_Starting_Trips",
    ROUND("Average_Trip_Duration_Minutes", 4) AS "Average_Trip_Duration_Minutes"
FROM ranked_trips
WHERE "Rank" <= 15
ORDER BY "Total_Starting_Trips" DESC NULLS LAST;
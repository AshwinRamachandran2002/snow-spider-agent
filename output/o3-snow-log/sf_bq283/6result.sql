WITH active_stations AS (   -- stations that are currently active
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),
trips_by_station AS (       -- trip metrics for active-start stations
    SELECT
        "start_station_id"        AS "station_id",
        COUNT(*)                  AS "total_trips",
        AVG("duration_minutes")   AS "avg_duration"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "start_station_id" IN (SELECT "station_id" FROM active_stations)
    GROUP BY "start_station_id"
),
overall_tot AS (            -- overall trip count from active stations
    SELECT SUM("total_trips") AS "overall_trips"
    FROM trips_by_station
),
ranked AS (                  -- rank stations by starting-trip count
    SELECT
        t."station_id",
        t."total_trips",
        (t."total_trips" / o."overall_trips") * 100 AS "pct_total",
        t."avg_duration",
        DENSE_RANK() OVER (ORDER BY t."total_trips" DESC) AS "rnk"
    FROM trips_by_station t
    CROSS JOIN overall_tot o
)
SELECT
    "station_id",
    "total_trips",
    ROUND("pct_total", 4)        AS "pct_of_all_start_trips",
    ROUND("avg_duration", 4)     AS "avg_trip_duration_minutes"
FROM ranked
WHERE "rnk" <= 15               -- include ties for 15th place
ORDER BY "rnk", "station_id";
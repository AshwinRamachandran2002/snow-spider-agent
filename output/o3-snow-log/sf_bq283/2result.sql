WITH active_stations AS (   -- stations that are currently active
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),

trips_from_active AS (      -- only trips that start at an active station
    SELECT  t."start_station_id"  AS "station_id",
            t."duration_minutes"
    FROM    AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN    active_stations a
      ON    t."start_station_id" = a."station_id"
),

per_station AS (            -- aggregate trip counts and average duration
    SELECT  "station_id",
            COUNT(*)                 AS "total_start_trips",
            AVG("duration_minutes")  AS "avg_trip_duration"
    FROM    trips_from_active
    GROUP BY "station_id"
),

overall_totals AS (         -- overall trips from all active stations
    SELECT SUM("total_start_trips") AS "overall_trips"
    FROM   per_station
),

ranked AS (                 -- rank stations and compute percentages
    SELECT  p."station_id",
            p."total_start_trips",
            ROUND(p."total_start_trips" / o."overall_trips" * 100, 4) AS "percent_of_all_starts",
            ROUND(p."avg_trip_duration", 4)                           AS "avg_trip_duration_minutes",
            DENSE_RANK() OVER (ORDER BY p."total_start_trips" DESC)   AS "rnk"
    FROM    per_station p
    CROSS JOIN overall_totals o
)

SELECT  "station_id",
        "total_start_trips",
        "percent_of_all_starts",
        "avg_trip_duration_minutes"
FROM    ranked
WHERE   "rnk" <= 15          -- top 15 ranks (including ties)
ORDER BY "rnk", "station_id";
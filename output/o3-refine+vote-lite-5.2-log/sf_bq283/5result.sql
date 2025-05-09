WITH active_stations AS (   -- stations that are currently active
    SELECT
        "station_id"
    FROM
        AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE
        UPPER("status") = 'ACTIVE'
),

active_trips AS (          -- trips that START at an active station
    SELECT
        t."start_station_id"   AS "station_id",
        t."duration_minutes"
    FROM
        AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
        JOIN active_stations s
              ON t."start_station_id" = s."station_id"
),

station_stats AS (         -- trip counts & average duration by station
    SELECT
        "station_id",
        COUNT(*)                         AS "total_start_trips",
        AVG("duration_minutes")          AS "avg_trip_duration"
    FROM
        active_trips
    GROUP BY
        "station_id"
),

overall AS (               -- total trips that START at any active station
    SELECT SUM("total_start_trips") AS "overall_trips"
    FROM   station_stats
),

ranked AS (                -- add rank (ties share the same rank)
    SELECT
        ss.*,
        o."overall_trips",
        DENSE_RANK() OVER (ORDER BY ss."total_start_trips" DESC) AS "rk"
    FROM
        station_stats ss
        CROSS JOIN overall o
)

SELECT
    "station_id",
    "total_start_trips",
    ROUND("total_start_trips" * 100.0 / "overall_trips", 4) AS "pct_of_active_trips",
    ROUND("avg_trip_duration", 4)                           AS "avg_trip_duration_minutes"
FROM
    ranked
WHERE
    "rk" <= 15                      -- keep top‑15 ranks (including ties)
ORDER BY
    "rk",                           -- order by rank
    "station_id";                   -- secondary order for determinism
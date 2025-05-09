WITH active_stations AS (   -- stations whose current status is “active”
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),

station_trip_stats AS (     -- trips that START at an active station
    SELECT
        t."start_station_id"          AS "station_id",
        COUNT(*)                      AS "trip_cnt",
        AVG(t."duration_minutes")     AS "avg_duration_min"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
          ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),

total_active_start_trips AS (  -- grand total of all starts from active stations
    SELECT SUM("trip_cnt") AS "grand_total"
    FROM station_trip_stats
),

ranked_stats AS (              -- rank stations by starting‑trip count
    SELECT
        sts.*,
        RANK() OVER (ORDER BY "trip_cnt" DESC) AS "rk"
    FROM station_trip_stats sts
)

SELECT
    rs."station_id",
    rs."trip_cnt"                                      AS "total_starting_trips",
    ROUND(rs."trip_cnt" * 100.0 / tat."grand_total", 4) AS "pct_of_all_active_starts",
    ROUND(rs."avg_duration_min", 4)                    AS "avg_trip_duration_min"
FROM ranked_stats rs
CROSS JOIN total_active_start_trips tat
WHERE rs."rk" <= 15          -- keep top 15 ranks (including ties)
ORDER BY rs."rk", rs."station_id";
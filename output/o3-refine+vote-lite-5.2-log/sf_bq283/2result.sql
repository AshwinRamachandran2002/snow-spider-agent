WITH active_stations AS (   -- stations that are currently active
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),
station_trip_stats AS (     -- trips that START at an active station
    SELECT
        t."start_station_id"           AS "station_id",
        COUNT(*)                       AS "total_start_trips",
        AVG(t."duration_minutes")      AS "avg_trip_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),
overall_totals AS (         -- grand‑total of all starts from active stations
    SELECT SUM("total_start_trips") AS "all_active_starts"
    FROM station_trip_stats
),
ranked AS (                 -- rank stations by start‑count (ties allowed)
    SELECT
        sts."station_id",
        sts."total_start_trips",
        ROUND(sts."avg_trip_minutes", 4)                                    AS "avg_trip_minutes",
        ROUND( (sts."total_start_trips" / ot."all_active_starts") * 100, 4) AS "pct_of_active_starts",
        RANK() OVER (ORDER BY sts."total_start_trips" DESC)                 AS "rnk"
    FROM station_trip_stats sts
    CROSS JOIN overall_totals ot
)
SELECT
    "station_id",
    "total_start_trips",
    "pct_of_active_starts",
    "avg_trip_minutes"
FROM ranked
WHERE "rnk" <= 15      -- keep top‑15 ranks (including ties)
ORDER BY "rnk", "station_id";
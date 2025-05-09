WITH active_stations AS (
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'          -- keep only currently‑active stations
),
station_trip_stats AS (
    SELECT
        t."start_station_id"           AS station_id,
        COUNT(*)                       AS trip_count,
        AVG(t."duration_minutes")      AS avg_duration_minutes
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),
overall_total AS (                          -- overall trips from active stations
    SELECT SUM(trip_count) AS total_trips
    FROM station_trip_stats
),
ranked AS (                                 -- rank stations by trip count
    SELECT
        sts.station_id,
        sts.trip_count,
        (sts.trip_count / ot.total_trips) * 100   AS pct_of_total,
        sts.avg_duration_minutes,
        DENSE_RANK() OVER (ORDER BY sts.trip_count DESC) AS rnk
    FROM station_trip_stats sts
    CROSS JOIN overall_total ot
)
SELECT
    station_id,
    trip_count                    AS total_starting_trips,
    ROUND(pct_of_total, 4)        AS pct_of_active_total,
    ROUND(avg_duration_minutes,4) AS avg_trip_duration_minutes
FROM ranked
WHERE rnk <= 15                       -- keep top‑15 ranks, including ties
ORDER BY rnk, station_id;
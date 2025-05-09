WITH active_stations AS (
    SELECT 
        "station_id"
    FROM 
        AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE 
        LOWER("status") = 'active'
), 
station_stats AS (
    SELECT
        t."start_station_id"               AS station_id,
        COUNT(*)                           AS trip_count,
        AVG(t."duration_minutes")          AS avg_duration
    FROM 
        AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS  t
        JOIN active_stations               s 
          ON t."start_station_id" = s."station_id"
    GROUP BY 
        t."start_station_id"
),
ranked AS (
    SELECT
        station_id,
        trip_count,
        avg_duration,
        100.0 * trip_count / SUM(trip_count) OVER () AS pct_of_total,
        RANK() OVER (ORDER BY trip_count DESC)      AS rk
    FROM 
        station_stats
)
SELECT
    station_id                                   AS "STATION_ID",
    trip_count                                   AS "TOTAL_STARTING_TRIPS",
    ROUND(pct_of_total, 4)                       AS "PCT_OF_TOTAL_START_TRIPS",
    ROUND(avg_duration, 4)                       AS "AVG_TRIP_DURATION_MINUTES"
FROM 
    ranked
WHERE 
    rk <= 15          -- keep top 15 ranks, including ties
ORDER BY 
    rk,
    station_id;
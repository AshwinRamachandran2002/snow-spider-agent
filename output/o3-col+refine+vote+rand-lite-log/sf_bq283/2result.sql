WITH active_stations AS (
    -- Stations that are currently in service
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE "status" ILIKE '%active%'
       OR "status" ILIKE '%open%'
       OR "status" ILIKE '%service%'
),
active_trip_totals AS (
    -- Trip counts & average duration for those active stations
    SELECT  t."start_station_id"         AS station_id,
            COUNT(*)                     AS trip_count,
            AVG(t."duration_minutes")    AS avg_minutes
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),
ranked AS (
    -- Rank stations by trip count (ties share the same rank)
    SELECT  RANK() OVER (ORDER BY trip_count DESC) AS station_rank,
            *
    FROM active_trip_totals
),
top15 AS (
    -- Keep the top-15 ranks, including any ties at rank 15
    SELECT *
    FROM ranked
    WHERE station_rank <= 15
)
SELECT  station_id,
        trip_count,
        ROUND(trip_count * 100.0 / SUM(trip_count) OVER (), 2) AS pct_of_active_trips,
        ROUND(avg_minutes, 2)                                 AS avg_duration_minutes
FROM top15
ORDER BY station_rank, station_id;
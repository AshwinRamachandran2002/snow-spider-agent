/* 1. Pick only stations whose current status is ‘active’.
   2. Count how many trips START from each of those stations and compute the
      average trip length.
   3. Work out the grand total of all trips that start at any active station
      so we can calculate percentages.
   4. Rank stations by their trip counts, keep the top-15 ranks (ties included),
      and return results ordered by that rank. */

WITH active_stations AS (    -- all currently-active stations
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),

station_trip_stats AS (     -- trip metrics for each active station
    SELECT
        t."start_station_id"           AS station_id,
        COUNT(*)                       AS total_start_trips,
        AVG(t."duration_minutes")      AS avg_duration_minutes
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
          ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),

overall_total AS (          -- grand total of trips from all active stations
    SELECT SUM(total_start_trips) AS overall_trips
    FROM station_trip_stats
),

ranked AS (                 -- add percentages and rank by trip count
    SELECT
        sts.station_id,
        sts.total_start_trips,
        ROUND(sts.total_start_trips / ot.overall_trips * 100, 4) 
            AS percent_of_total_start_trips,
        ROUND(sts.avg_duration_minutes, 4) AS avg_duration_minutes,
        RANK() OVER (ORDER BY sts.total_start_trips DESC) AS rnk
    FROM station_trip_stats sts
    CROSS JOIN overall_total ot
)

SELECT
    station_id,
    total_start_trips,
    percent_of_total_start_trips,
    avg_duration_minutes
FROM ranked
WHERE rnk <= 15                       -- keep top-15 ranks (ties included)
ORDER BY rnk, station_id;             -- ordered by the station’s rank
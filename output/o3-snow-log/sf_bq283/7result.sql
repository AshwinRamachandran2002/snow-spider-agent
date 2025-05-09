/* 1) pick only stations whose current status is active
   2) keep only trips that START at those active stations
   3) aggregate trip count & average duration for each station
   4) compute each station’s share (%) of all trips that start at active stations
   5) rank stations by trip count (ties share the same rank)
   6) return every station whose rank is ≤ 15 (includes any ties at the 15-th rank)  */

WITH active_stations AS (
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
), 
active_trips AS (
    SELECT
        t."start_station_id"      AS "station_id",
        t."duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
          ON t."start_station_id" = s."station_id"
), 
station_stats AS (
    SELECT
        "station_id",
        COUNT(*)                       AS "total_trips",
        AVG("duration_minutes")        AS "avg_duration"
    FROM active_trips
    GROUP BY "station_id"
), 
overall AS (
    SELECT SUM("total_trips") AS "overall_trips"
    FROM station_stats
), 
ranked AS (
    SELECT
        ss."station_id",
        ss."total_trips",
        ROUND( (ss."total_trips" / o."overall_trips") * 100, 4)   AS "pct_of_total",
        ROUND( ss."avg_duration", 4 )                              AS "avg_duration_minutes",
        DENSE_RANK() OVER (ORDER BY ss."total_trips" DESC)         AS "rk"
    FROM station_stats ss
    CROSS JOIN overall o
)
SELECT
    "station_id",
    "total_trips",
    "pct_of_total",
    "avg_duration_minutes"
FROM ranked
WHERE "rk" <= 15
ORDER BY "rk", "station_id";
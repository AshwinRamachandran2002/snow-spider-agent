WITH active_trips AS (
    SELECT t."start_station_id",
           t."duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS   t
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s
      ON t."start_station_id" = s."station_id"
    WHERE s."status" ILIKE 'active'
),
station_stats AS (
    SELECT "start_station_id"                      AS "station_id",
           COUNT(*)                                AS "trip_count",
           AVG("duration_minutes")                 AS "avg_duration_minutes"
    FROM active_trips
    GROUP BY "start_station_id"
),
tot AS (
    SELECT SUM("trip_count") AS "grand_total"
    FROM station_stats
),
ranked AS (
    SELECT s.*,
           DENSE_RANK() OVER (ORDER BY s."trip_count" DESC) AS "rank"
    FROM station_stats s
)
SELECT  r."station_id",
        r."trip_count",
        ROUND(r."trip_count" * 100.0 / t."grand_total", 2) AS "pct_of_active_start_trips",
        ROUND(r."avg_duration_minutes", 2)                 AS "avg_duration_minutes"
FROM ranked r
CROSS JOIN tot t
WHERE r."rank" <= 15
ORDER BY r."rank", r."station_id";
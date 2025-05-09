WITH active_stations AS (
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE "status" ILIKE '%active%'
),
trip_counts AS (
    SELECT
        t."start_station_id"                   AS "station_id",
        COUNT(*)                               AS "starting_trip_count"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),
ranked AS (
    SELECT
        "station_id",
        "starting_trip_count",
        DENSE_RANK() OVER (ORDER BY "starting_trip_count" DESC) AS "station_rank"
    FROM trip_counts
),
overall AS (
    SELECT COUNT(*) AS "overall_trips"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
)
SELECT
    r."station_id",
    r."starting_trip_count",
    ROUND(r."starting_trip_count" * 100.0 / o."overall_trips", 2) AS "pct_of_active_starts",
    AVG(t."duration_minutes")                                     AS "avg_duration_minutes"
FROM ranked r
JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
  ON t."start_station_id" = r."station_id"
JOIN overall o
WHERE r."station_rank" <= 15
GROUP BY
    r."station_id",
    r."starting_trip_count",
    o."overall_trips",
    r."station_rank"
ORDER BY r."station_rank";
WITH active_station_trips AS (
    SELECT
        t."start_station_id"                                AS "station_id",
        COUNT(*)                                            AS "total_start_trips",
        AVG(t."duration_minutes")                           AS "avg_duration",
        RANK() OVER (ORDER BY COUNT(*) DESC)                AS "station_rank"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS     t
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS  s
      ON t."start_station_id" = s."station_id"
    WHERE s."status" ILIKE '%active%'
    GROUP BY t."start_station_id"
),
overall AS (
    SELECT COUNT(*) AS "overall_active_start_trips"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS     t
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS  s
      ON t."start_station_id" = s."station_id"
    WHERE s."status" ILIKE '%active%'
)

SELECT
    a."station_id",
    a."total_start_trips",
    ROUND(a."total_start_trips" * 100.0 / o."overall_active_start_trips", 2) AS "percent_of_active_trips",
    a."avg_duration",
    a."station_rank"
FROM active_station_trips a
CROSS JOIN overall o
WHERE a."station_rank" <= 15
ORDER BY a."station_rank", a."station_id";
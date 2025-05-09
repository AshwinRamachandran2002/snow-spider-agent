WITH active_station_trips AS (
    /* 1.  Trip metrics for every station whose current status is 'active'            */
    SELECT
        t."start_station_id"                                           AS "station_id",
        COUNT(*)                                                        AS "starting_trip_count",
        AVG(t."duration_minutes")                                       AS "avg_duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS     t
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS  s
          ON t."start_station_id" = s."station_id"
    WHERE s."status" ILIKE '%active%'
    GROUP BY t."start_station_id"
), ranked AS (
    /* 2.  Rank stations by trip count and compute total trips from all active stations */
    SELECT
        ast.*,
        RANK() OVER (ORDER BY ast."starting_trip_count" DESC)           AS "rank_by_trips",
        SUM(ast."starting_trip_count") OVER ()                          AS "total_active_start_trips"
    FROM active_station_trips ast
)
SELECT
    "station_id",
    "starting_trip_count",
    ROUND(100.0 * "starting_trip_count" / "total_active_start_trips", 2) AS "pct_of_active_start_trips",
    ROUND("avg_duration_minutes", 2)                                     AS "avg_duration_minutes"
FROM ranked
WHERE "rank_by_trips" <= 15                 -- keep top-15 ranks (ties included)
ORDER BY "rank_by_trips", "station_id";
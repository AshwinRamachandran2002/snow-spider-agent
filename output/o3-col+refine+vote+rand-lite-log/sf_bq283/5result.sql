WITH active_trips AS (
    -- Trips that begin at stations currently marked as 'active'
    SELECT
        t."start_station_id",
        COUNT(*)                              AS "total_starting_trips",
        AVG(t."duration_minutes")             AS "avg_duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS     AS t
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS  AS s
          ON t."start_station_id" = s."station_id"
    WHERE s."status" = 'active'
    GROUP BY t."start_station_id"
),
ranked AS (
    -- Rank stations by total starting trips (dense rank keeps ties)
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY "total_starting_trips" DESC) AS "rank_by_starts"
    FROM active_trips
),
grand_total AS (
    -- Overall total of trips that start from active stations
    SELECT SUM("total_starting_trips") AS "grand_total"
    FROM active_trips
)
SELECT
    r."start_station_id"                         AS "station_id",
    r."total_starting_trips",
    ROUND(100.0 * r."total_starting_trips" / g."grand_total", 2) AS "pct_of_active_starts",
    ROUND(r."avg_duration_minutes", 2)           AS "avg_duration_minutes"
FROM ranked r
CROSS JOIN grand_total g
WHERE r."rank_by_starts" <= 15          -- include all ties within top 15 ranks
ORDER BY r."rank_by_starts", r."start_station_id";
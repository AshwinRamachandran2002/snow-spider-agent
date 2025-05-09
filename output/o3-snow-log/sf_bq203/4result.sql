WITH ada_station_names AS (
    SELECT DISTINCT "station_name"
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES
    WHERE "entry" = TRUE
      AND "ada_compliant" = TRUE
),
station_flags AS (
    SELECT 
        s."borough_name"           AS borough,
        s."station_id",
        CASE 
            WHEN a."station_name" IS NOT NULL THEN 1 
            ELSE 0 
        END                       AS ada_flag
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS s
    LEFT JOIN ada_station_names a
           ON s."station_name" = a."station_name"
)
SELECT
    borough,
    COUNT(*)                               AS total_stations,
    SUM(ada_flag)                          AS ada_accessible_stations,
    ROUND(100.0 * SUM(ada_flag) / COUNT(*), 2) AS pct_ada_accessible
FROM station_flags
GROUP BY borough
ORDER BY pct_ada_accessible DESC NULLS LAST;
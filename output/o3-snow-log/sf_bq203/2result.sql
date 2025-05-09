WITH stations AS (
    SELECT 
        "station_id",
        "station_name",
        "borough_name"
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS
),
station_access AS (
    SELECT
        s."station_id",
        s."borough_name",
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES e
                WHERE   e."station_name" = s."station_name"
                    AND e."entry" = TRUE
                    AND e."ada_compliant" = TRUE
            )
            THEN 1 ELSE 0
        END AS "has_ada_entry"
    FROM stations s
)
SELECT
    "borough_name"                               AS "borough",
    COUNT(*)                                     AS "total_stations",
    SUM("has_ada_entry")                         AS "ada_accessible_stations",
    ROUND(SUM("has_ada_entry") * 100.0 / COUNT(*), 2) 
                                                 AS "percent_accessible"
FROM station_access
GROUP BY "borough_name"
ORDER BY "percent_accessible" DESC NULLS LAST;
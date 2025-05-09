WITH accessible_stations AS (
    /* Stations that have at least one entrance flagged as both ADA–compliant and an actual entry */
    SELECT DISTINCT
           s."station_id"
    FROM   NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS            s
    JOIN   NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES   e
           ON s."station_name" = e."station_name"
    WHERE  e."entry" = TRUE
      AND  e."ada_compliant" = TRUE
),
station_counts AS (
    /* Total stations and those with an ADA-compliant entrance by borough */
    SELECT
        s."borough_name"                        AS borough,
        COUNT(DISTINCT s."station_id")          AS total_stations,
        COUNT(DISTINCT a."station_id")          AS accessible_stations
    FROM   NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS s
    LEFT  JOIN accessible_stations               a
           ON s."station_id" = a."station_id"
    GROUP BY
        s."borough_name"
)
SELECT
    borough,
    total_stations,
    accessible_stations,
    ROUND(accessible_stations * 100.0 / total_stations, 2) AS percent_accessible
FROM   station_counts
ORDER  BY percent_accessible DESC NULLS LAST;
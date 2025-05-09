WITH
-- total number of stations per borough
total_stations AS (
    SELECT
        "borough_name"                     AS borough,
        COUNT(DISTINCT "station_id")       AS total_stations
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS
    GROUP BY "borough_name"
),

-- list of station names that have at least one ADA–compliant entrance that is an actual entry
accessible_station_names AS (
    SELECT DISTINCT
        "station_name"
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES
    WHERE "entry" = TRUE
      AND "ada_compliant" = TRUE
),

-- count of such accessible stations per borough
accessible_by_borough AS (
    SELECT
        s."borough_name"                   AS borough,
        COUNT(DISTINCT s."station_id")     AS accessible_stations
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS          s
    JOIN accessible_station_names                        a
      ON s."station_name" = a."station_name"
    GROUP BY s."borough_name"
),

-- combine and compute percentage
combined AS (
    SELECT
        t.borough,
        t.total_stations,
        COALESCE(a.accessible_stations, 0)                                 AS accessible_stations,
        ROUND(COALESCE(a.accessible_stations, 0) * 100.0 / t.total_stations, 4)
                                                                            AS percent_accessible
    FROM total_stations                t
    LEFT JOIN accessible_by_borough    a  ON t.borough = a.borough
)

SELECT
    borough,
    total_stations,
    accessible_stations,
    percent_accessible
FROM combined
ORDER BY percent_accessible DESC NULLS LAST;
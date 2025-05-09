WITH station_borough AS (
    SELECT 
        "station_id",
        "station_name",
        "borough_name"
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS
), 

ada_stations AS (
    /* stations that have AT LEAST one entrance that is both an actual entry and ADA-compliant */
    SELECT DISTINCT
        s."station_id"
    FROM station_borough            s
    JOIN NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES e
      ON s."station_name" = e."station_name"
    WHERE e."entry" = TRUE
      AND e."ada_compliant" = TRUE
)

SELECT
    sb."borough_name"                                            AS borough,
    COUNT(DISTINCT sb."station_id")                              AS total_stations,
    COUNT(DISTINCT CASE WHEN a."station_id" IS NOT NULL 
                         THEN sb."station_id" END)               AS ada_entry_stations,
    ROUND(
        COUNT(DISTINCT CASE WHEN a."station_id" IS NOT NULL 
                            THEN sb."station_id" END)
        * 100.0
        / COUNT(DISTINCT sb."station_id"),
        2
    )                                                            AS percentage_ada
FROM station_borough sb
LEFT JOIN ada_stations a
       ON sb."station_id" = a."station_id"
GROUP BY sb."borough_name"
ORDER BY percentage_ada DESC NULLS LAST;
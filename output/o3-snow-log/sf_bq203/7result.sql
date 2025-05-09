WITH ada_station_names AS (
    /* every station name that has at least one entrance
       which is both an actual entry point and ADA-compliant */
    SELECT DISTINCT
           LOWER("station_name") AS station_name_lc
    FROM   NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES
    WHERE  "entry" = TRUE
      AND  "ada_compliant" = TRUE
),
stations_flagged AS (
    /* mark each subway station with whether it has such an ADA entrance */
    SELECT
        s."station_id",
        s."borough_name"      AS borough,
        CASE 
            WHEN a.station_name_lc IS NOT NULL THEN 1 
            ELSE 0 
        END                   AS ada_flag
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS            s
    LEFT JOIN ada_station_names                            a
           ON LOWER(s."station_name") = a.station_name_lc
)
SELECT
    borough,
    COUNT(DISTINCT "station_id")                          AS total_stations,
    SUM(ada_flag)                                         AS ada_stations,
    ROUND( SUM(ada_flag) * 100.0 
           / COUNT(DISTINCT "station_id"), 2)             AS ada_percentage
FROM   stations_flagged
GROUP  BY borough
ORDER  BY ada_percentage DESC NULLS LAST;
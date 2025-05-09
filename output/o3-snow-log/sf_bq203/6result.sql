WITH station_ada_flag AS (
    /* Determine, for every subway station, whether it has
       at least one entrance that is BOTH an entry point
       and ADA-compliant                                                  */
    SELECT
        s."station_id",
        s."borough_name"                              AS "borough",
        /* 1 if any qualifying entrance, else 0 */
        MAX(
            CASE
                WHEN e."entry"       = TRUE
                 AND e."ada_compliant" = TRUE
                THEN 1 ELSE 0
            END
        )                                             AS "has_ada_entry"
    FROM  "NEW_YORK_PLUS"."NEW_YORK_SUBWAY"."STATIONS"           s
    LEFT JOIN "NEW_YORK_PLUS"."NEW_YORK_SUBWAY"."STATION_ENTRANCES" e
           ON s."station_name" = e."station_name"
    GROUP BY
        s."station_id",
        s."borough_name"
),
borough_totals AS (
    /* Count total stations and ADA-capable stations per borough */
    SELECT
        "borough",
        COUNT(*)                            AS "total_stations",
        SUM("has_ada_entry")                AS "ada_stations",
        ROUND( 100.0 * SUM("has_ada_entry") / COUNT(*), 2) 
                                            AS "percent_ada"
    FROM station_ada_flag
    GROUP BY "borough"
)

SELECT
    "borough",
    "total_stations",
    "ada_stations",
    "percent_ada"
FROM borough_totals
ORDER BY "percent_ada" DESC NULLS LAST;
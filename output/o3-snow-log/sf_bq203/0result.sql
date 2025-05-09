SELECT
    s."borough_name"                                           AS "borough",
    COUNT(*)                                                   AS "total_stations",
    SUM(
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES e
                WHERE   e."station_name" = s."station_name"
                    AND e."entry"       = TRUE
                    AND e."ada_compliant" = TRUE
            )
            THEN 1 ELSE 0
        END
    )                                                          AS "ada_stations",
    ROUND(
        100.0 * SUM(
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES e
                    WHERE   e."station_name" = s."station_name"
                        AND e."entry"       = TRUE
                        AND e."ada_compliant" = TRUE
                )
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        4
    )                                                          AS "ada_station_pct"
FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS s
WHERE s."borough_name" IS NOT NULL
GROUP BY s."borough_name"
ORDER BY "ada_station_pct" DESC NULLS LAST;
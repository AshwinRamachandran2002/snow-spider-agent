WITH ada_station_ids AS (
    SELECT DISTINCT s."station_id"
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS s
    JOIN NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES se
        ON s."station_name" = se."station_name" AND s."division" = se."division"
    WHERE se."ada_compliant" = TRUE
)
SELECT
    s."borough_name",
    ROUND(
        COUNT(DISTINCT CASE WHEN s."station_id" IN (SELECT "station_id" FROM ada_station_ids) THEN s."station_id" END) * 100.0
        /
        COUNT(DISTINCT s."station_id"), 4
    ) AS "percentage_ada_stations"
FROM
    NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS s
GROUP BY
    s."borough_name"
ORDER BY
    s."borough_name";
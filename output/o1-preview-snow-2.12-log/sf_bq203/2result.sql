WITH total_stations AS (
    SELECT "borough_name", COUNT(DISTINCT "station_id") AS "Total_number_of_stations"
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS
    GROUP BY "borough_name"
),
ada_stations AS (
    SELECT s."borough_name", COUNT(DISTINCT s."station_id") AS "Number_of_ADA_stations"
    FROM NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATIONS s
    JOIN NEW_YORK_PLUS.NEW_YORK_SUBWAY.STATION_ENTRANCES se
        ON s."station_name" = se."station_name"
    WHERE se."entry" = TRUE AND se."ada_compliant" = TRUE
    GROUP BY s."borough_name"
)
SELECT 
    t."borough_name" AS "Borough",
    t."Total_number_of_stations",
    COALESCE(a."Number_of_ADA_stations", 0) AS "Number_of_ADA_stations",
    ROUND(COALESCE(a."Number_of_ADA_stations", 0) * 100.0 / t."Total_number_of_stations", 4) AS "Percentage_of_ADA_stations"
FROM total_stations t
LEFT JOIN ada_stations a
    ON t."borough_name" = a."borough_name"
ORDER BY "Percentage_of_ADA_stations" DESC NULLS LAST;
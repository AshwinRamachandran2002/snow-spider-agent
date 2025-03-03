SELECT
    s."borough_name" AS "Borough",
    COUNT(DISTINCT s."station_id") AS "Total_number_of_stations",
    COUNT(DISTINCT CASE WHEN se."entry" = TRUE AND se."ada_compliant" = TRUE THEN s."station_id" END) AS "Number_of_ADA_stations",
    ROUND((COUNT(DISTINCT CASE WHEN se."entry" = TRUE AND se."ada_compliant" = TRUE THEN s."station_id" END) * 100.0) / COUNT(DISTINCT s."station_id"), 4) AS "Percentage_of_ADA_stations"
FROM "NEW_YORK_PLUS"."NEW_YORK_SUBWAY"."STATIONS" s
LEFT JOIN "NEW_YORK_PLUS"."NEW_YORK_SUBWAY"."STATION_ENTRANCES" se
    ON s."station_name" = se."station_name"
GROUP BY s."borough_name"
ORDER BY "Percentage_of_ADA_stations" DESC NULLS LAST;
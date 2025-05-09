SELECT
  s."borough_name",
  ROUND(
    COUNT(DISTINCT CASE WHEN se."ada_compliant" = TRUE AND se."exit_only" = FALSE THEN s."station_id" END) * 100.0
    /
    COUNT(DISTINCT s."station_id"),
    4
  ) AS "percentage_ada_stations"
FROM
  "NEW_YORK_PLUS"."NEW_YORK_SUBWAY"."STATIONS" s
LEFT JOIN
  "NEW_YORK_PLUS"."NEW_YORK_SUBWAY"."STATION_ENTRANCES" se
    ON s."station_name" = se."station_name"
GROUP BY
  s."borough_name"
ORDER BY
  s."borough_name";
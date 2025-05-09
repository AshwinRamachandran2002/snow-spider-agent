WITH total_stations AS (
  SELECT "borough_name", COUNT(DISTINCT "station_id") AS "total_stations"
  FROM "NEW_YORK_PLUS"."NEW_YORK_SUBWAY"."STATIONS"
  GROUP BY "borough_name"
),
ada_stations AS (
  SELECT s."borough_name", COUNT(DISTINCT s."station_id") AS "ada_stations"
  FROM "NEW_YORK_PLUS"."NEW_YORK_SUBWAY"."STATIONS" s
  JOIN (
    SELECT DISTINCT "station_name"
    FROM "NEW_YORK_PLUS"."NEW_YORK_SUBWAY"."STATION_ENTRANCES"
    WHERE "ada_compliant" = TRUE
  ) ada
  ON s."station_name" = ada."station_name"
  GROUP BY s."borough_name"
)
SELECT t."borough_name",
       ROUND(COALESCE((a."ada_stations" * 100.0) / t."total_stations", 0), 4) AS "percentage_ada_stations"
FROM total_stations t
LEFT JOIN ada_stations a ON t."borough_name" = a."borough_name";
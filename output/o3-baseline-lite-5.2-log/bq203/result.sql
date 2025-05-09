WITH ada_stations AS (
  -- stations that have at least one entrance that is both an entry point AND ADA–compliant
  SELECT DISTINCT
         UPPER(station_name) AS station_name_upper
  FROM `bigquery-public-data.new_york_subway.station_entrances`
  WHERE entry = TRUE
    AND ada_compliant = TRUE
),
all_stations AS (
  -- every subway station with its borough
  SELECT
      station_id,
      UPPER(station_name) AS station_name_upper,
      borough_name
  FROM `bigquery-public-data.new_york_subway.stations`
)
SELECT
    borough_name                                        AS borough,
    COUNT(DISTINCT station_id)                          AS total_stations,
    COUNT(DISTINCT IF(a.station_name_upper IS NOT NULL,
                      station_id,
                      NULL))                            AS ada_entry_stations,
    ROUND(
        SAFE_DIVIDE(
            COUNT(DISTINCT IF(a.station_name_upper IS NOT NULL, station_id, NULL)),
            COUNT(DISTINCT station_id)
        ) * 100,
        4
    )                                                   AS pct_ada_entry_stations
FROM all_stations s
LEFT JOIN ada_stations a
       USING (station_name_upper)
GROUP BY borough_name
ORDER BY pct_ada_entry_stations DESC, borough_name;
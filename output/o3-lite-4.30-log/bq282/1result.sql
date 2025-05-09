SELECT district AS council_district
FROM (
  SELECT
    sd.council_district AS district,
    COUNT(*) AS trip_cnt
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS sd
    ON sd.station_id = t.start_station_id
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS ed
    ON ed.station_id = SAFE_CAST(t.end_station_id AS INT64)
  WHERE SAFE_CAST(t.end_station_id AS INT64) IS NOT NULL
    AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64)
    AND sd.council_district = ed.council_district
    AND sd.status = 'active'
    AND ed.status = 'active'
  GROUP BY district
  ORDER BY trip_cnt DESC
  LIMIT 1
);
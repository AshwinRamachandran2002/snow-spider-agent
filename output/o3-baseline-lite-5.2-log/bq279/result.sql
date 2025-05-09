WITH trip_stations AS (
  -- stations that appeared in trips during 2013 or 2014
  SELECT
    EXTRACT(YEAR FROM start_time) AS yr,
    start_station_id              AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)

  UNION ALL

  SELECT
    EXTRACT(YEAR FROM start_time)      AS yr,
    SAFE_CAST(end_station_id AS INT64) AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)
),
distinct_year_station AS (
  -- unique (year, station) combinations observed in those trips
  SELECT DISTINCT
    yr,
    station_id
  FROM trip_stations
  WHERE station_id IS NOT NULL
),
station_status AS (
  -- current status of every station (only active or closed)
  SELECT
    station_id,
    LOWER(status) AS status
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE LOWER(status) IN ('active', 'closed')
)
SELECT
  d.yr          AS year,
  s.status,
  COUNT(DISTINCT d.station_id) AS station_count
FROM distinct_year_station AS d
JOIN station_status        AS s
  ON d.station_id = s.station_id
GROUP BY
  year,
  status
ORDER BY
  year,
  status;
WITH trip_stations AS (
  -- stations that appear in trips during 2013‑2014
  SELECT
    EXTRACT(YEAR FROM `start_time`) AS year,
    `start_station_id`              AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM `start_time`) IN (2013, 2014)

  UNION ALL

  SELECT
    EXTRACT(YEAR FROM `start_time`) AS year,
    CAST(`end_station_id` AS INT64) AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM `start_time`) IN (2013, 2014)
),
station_status AS (
  -- current status of each station (active / closed)
  SELECT DISTINCT
    `station_id`,
    `status`
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE `status` IN ('active', 'closed')
)
SELECT
  ts.year,
  COUNT(DISTINCT IF(ss.status = 'active', ts.station_id, NULL)) AS active_stations,
  COUNT(DISTINCT IF(ss.status = 'closed', ts.station_id, NULL)) AS closed_stations
FROM trip_stations AS ts
LEFT JOIN station_status AS ss
  USING (`station_id`)
GROUP BY ts.year
ORDER BY ts.year;
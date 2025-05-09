WITH year_station_ids AS (
  -- stations that appeared as start stations in 2013‑2014 trips
  SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    start_station_id AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)

  UNION DISTINCT

  -- stations that appeared as end stations in 2013‑2014 trips
  SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    SAFE_CAST(end_station_id AS INT64) AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)
),
station_status AS (
  SELECT
    station_id,
    LOWER(status) AS status
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
)
SELECT
  ys.year,
  COUNT(DISTINCT CASE WHEN ss.status = 'active' THEN ys.station_id END)  AS active_stations,
  COUNT(DISTINCT CASE WHEN ss.status = 'closed' THEN ys.station_id END)  AS closed_stations
FROM year_station_ids AS ys
LEFT JOIN station_status AS ss
  ON ys.station_id = ss.station_id
GROUP BY ys.year
ORDER BY ys.year;
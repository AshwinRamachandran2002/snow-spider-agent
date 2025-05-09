-- Number of distinct bike-share stations used in 2013 & 2014 rides,
-- broken out by their current status (active vs. closed)
WITH trips_13_14 AS (
  SELECT DISTINCT
         CAST(start_station_id AS INT64) AS station_id,
         EXTRACT(YEAR FROM start_time)   AS yr
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)
),
status_counts AS (
  SELECT
    t.yr,
    LOWER(s.status)            AS station_status,
    COUNT(DISTINCT t.station_id) AS station_cnt
  FROM trips_13_14 AS t
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s
    ON t.station_id = s.station_id
  WHERE LOWER(s.status) IN ('active', 'closed')
  GROUP BY t.yr, station_status
)
SELECT
  yr,
  SUM(CASE WHEN station_status = 'active' THEN station_cnt END) AS active_stations,
  SUM(CASE WHEN station_status = 'closed' THEN station_cnt END) AS closed_stations
FROM status_counts
GROUP BY yr
ORDER BY yr;
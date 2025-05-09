/* Distinct bike‑share stations with trips in 2013 and 2014,
   broken out by their current status (‘active’ or ‘closed’). */

WITH trips_per_year AS (
  -- gather every station that appeared in a trip (as start OR end)
  SELECT
    EXTRACT(YEAR FROM start_time) AS yr,
    start_station_id              AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)

  UNION ALL

  SELECT
    EXTRACT(YEAR FROM start_time)             AS yr,
    SAFE_CAST(end_station_id AS INT64)        AS station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_time) IN (2013, 2014)
),

station_status AS (
  SELECT
    station_id,
    LOWER(status) AS status          -- normalise for easy comparison
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
)

SELECT
  yr AS year,
  COUNT(DISTINCT IF(status = 'active', station_id, NULL)) AS active_stations,
  COUNT(DISTINCT IF(status = 'closed', station_id, NULL)) AS closed_stations
FROM trips_per_year
JOIN station_status USING (station_id)
GROUP BY year
ORDER BY year;
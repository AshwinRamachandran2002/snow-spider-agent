WITH daily AS (
  SELECT
    DATE(start_time) AS ride_date,
    COUNT(*) AS trips
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE LOWER(subscriber_type) = 'student membership'
    AND LOWER(bike_type) = 'electric'
    AND duration_minutes > 10
    AND NOT (
      LOWER(start_station_name) LIKE '%mobile station%' OR
      LOWER(start_station_name) LIKE '%repair shop%'  OR
      LOWER(end_station_name)   LIKE '%mobile station%' OR
      LOWER(end_station_name)   LIKE '%repair shop%'
    )
  GROUP BY ride_date
)
SELECT
  ride_date AS date,
  trips AS max_ride_count
FROM (
  SELECT
    daily.*,
    ROW_NUMBER() OVER (ORDER BY trips DESC, ride_date) AS rn
  FROM daily
)
WHERE rn = 1;
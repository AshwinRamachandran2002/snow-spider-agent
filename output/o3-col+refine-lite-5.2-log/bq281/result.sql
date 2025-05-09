-- Highest single‑day total of qualifying electric‑bike rides
SELECT MAX(daily_rides) AS highest_daily_total
FROM (
  SELECT
    DATE(`start_time`)        AS ride_date,
    COUNT(*)                  AS daily_rides
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE LOWER(`subscriber_type`) = 'student membership'
    AND LOWER(`bike_type`)       = 'electric'
    AND `duration_minutes`      > 10
    AND NOT (
          LOWER(`start_station_name`) LIKE '%mobile station%'
       OR LOWER(`start_station_name`) LIKE '%repair shop%'
       OR LOWER(`end_station_name`)   LIKE '%mobile station%'
       OR LOWER(`end_station_name`)   LIKE '%repair shop%'
    )
  GROUP BY ride_date
);
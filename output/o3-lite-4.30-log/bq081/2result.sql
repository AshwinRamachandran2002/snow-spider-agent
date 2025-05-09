WITH ranked AS (
  SELECT
    r.name AS region,
    t.trip_id,
    t.duration_sec AS ride_duration,
    t.start_date AS start_time,
    t.start_station_name AS start_station,
    t.member_gender AS gender,
    ROW_NUMBER() OVER (PARTITION BY r.region_id ORDER BY t.start_date DESC) AS rn
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
    ON CAST(t.start_station_id AS STRING) = s.station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS r
    ON s.region_id = r.region_id
  WHERE DATE(t.start_date) BETWEEN '2014-01-01' AND '2017-12-31'
)
SELECT
  region,
  trip_id,
  ride_duration,
  start_time,
  start_station,
  gender
FROM ranked
WHERE rn = 1
ORDER BY region;
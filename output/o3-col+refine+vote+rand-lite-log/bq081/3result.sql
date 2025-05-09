-- Latest ride (2014-2017) per Bay-Area bikeshare region
WITH trips_with_region AS (
  SELECT
    r.name                           AS region_name,
    r.region_id,
    t.trip_id,
    t.duration_sec,
    t.start_date,
    t.start_station_name,
    t.member_gender
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`        AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
    ON CAST(t.start_station_id AS STRING) = s.station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`      AS r
    ON s.region_id = r.region_id
  WHERE t.start_date BETWEEN TIMESTAMP('2014-01-01') AND TIMESTAMP('2017-12-31')
)

SELECT
  region_name,
  trip_id,
  duration_sec          AS ride_duration_sec,
  start_date            AS start_time,
  start_station_name    AS start_station,
  member_gender
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY region_id ORDER BY start_date DESC) AS rn
  FROM trips_with_region
)
WHERE rn = 1
ORDER BY region_name;
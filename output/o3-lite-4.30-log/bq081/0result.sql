SELECT
  region_name        AS region,
  trip_id,
  duration_sec       AS ride_duration,
  start_date         AS start_time,
  start_station_name AS start_station,
  member_gender      AS gender
FROM (
  SELECT
    r.name AS region_name,
    t.trip_id,
    t.duration_sec,
    t.start_date,
    t.start_station_name,
    t.member_gender,
    ROW_NUMBER() OVER (
      PARTITION BY r.name
      ORDER BY t.start_date DESC, t.trip_id
    ) AS rn
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`        AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
    ON CAST(si.station_id AS INT64) = t.start_station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`      AS r
    ON r.region_id = si.region_id
  WHERE t.start_date BETWEEN '2014-01-01' AND '2017-12-31'
)
WHERE rn = 1
ORDER BY region;
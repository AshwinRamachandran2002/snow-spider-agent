WITH trips_with_region AS (
  SELECT
    r.name                         AS region_name,
    t.trip_id,
    t.duration_sec,
    t.start_date                   AS start_time,
    t.start_station_name,
    t.member_gender
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`          AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`   AS si
       ON CAST(si.station_id AS INT64) = t.start_station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`        AS r
       ON r.region_id = si.region_id
  WHERE t.start_date BETWEEN '2014-01-01' AND '2017-12-31 23:59:59'
),

latest_per_region AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY region_name
                       ORDER BY start_time DESC, trip_id DESC) AS rn
  FROM trips_with_region
)

SELECT
  region_name,
  trip_id,
  duration_sec,
  start_time,
  start_station_name,
  member_gender
FROM latest_per_region
WHERE rn = 1
ORDER BY region_name;
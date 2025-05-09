WITH trips_per_region AS (
  SELECT
    r.name                           AS region_name,
    t.trip_id,
    t.duration_sec,
    t.start_date                     AS start_time,
    t.start_station_name,
    t.member_gender,
    ROW_NUMBER() OVER (
        PARTITION BY r.region_id
        ORDER BY t.start_date DESC, t.trip_id DESC            -- latest ride per region
    )                                                         AS rn
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`  AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
       ON CAST(t.start_station_id AS STRING) = s.station_id              -- station lookup
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS r
       ON r.region_id = s.region_id                                       -- region lookup
  WHERE t.start_date BETWEEN '2014-01-01' AND '2017-12-31 23:59:59'       -- years 2014‑2017
)

SELECT
  region_name,
  trip_id,
  duration_sec,
  start_time,
  start_station_name,
  member_gender
FROM trips_per_region
WHERE rn = 1                       -- keep only the latest ride per region
ORDER BY region_name;
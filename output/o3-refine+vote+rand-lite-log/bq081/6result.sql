WITH trips_with_region AS (
  SELECT
    r.name                          AS region_name,
    t.trip_id,
    t.duration_sec                  AS ride_duration,
    t.start_date                    AS start_time,
    t.start_station_name,
    t.member_gender,
    ROW_NUMBER() OVER (
        PARTITION BY r.name
        ORDER BY t.start_date DESC, t.trip_id DESC
    )                               AS rn
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`        AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
       ON CAST(t.start_station_id AS STRING) = s.station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`      AS r
       ON s.region_id = r.region_id
  WHERE t.start_date >= TIMESTAMP('2014-01-01')
    AND t.start_date <  TIMESTAMP('2018-01-01')
)
SELECT
  region_name,
  trip_id,
  ride_duration,
  start_time,
  start_station_name,
  member_gender
FROM trips_with_region
WHERE rn = 1
ORDER BY region_name;
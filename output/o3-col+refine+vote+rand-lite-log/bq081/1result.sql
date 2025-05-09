-- Latest (2014-2017) bike-share ride for every region
WITH ordered_rides AS (
  SELECT
    r.name                                             AS region,
    t.trip_id                                          AS latest_trip_id,
    t.duration_sec                                     AS ride_duration_sec,
    t.start_date                                       AS ride_start_time,
    t.start_station_name                               AS starting_station,
    t.member_gender                                    AS rider_gender,
    ROW_NUMBER() OVER (PARTITION BY r.name
                       ORDER BY t.start_date DESC)     AS rn
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`        AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
       ON t.start_station_id = CAST(s.station_id AS INT64)
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`      AS r
       ON s.region_id = r.region_id
  WHERE t.start_date BETWEEN '2014-01-01' AND '2017-12-31'
)
SELECT
  region,
  latest_trip_id,
  ride_duration_sec,
  ride_start_time,
  starting_station,
  rider_gender
FROM ordered_rides
WHERE rn = 1
ORDER BY region;
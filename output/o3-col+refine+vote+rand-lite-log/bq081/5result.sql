-- latest ride (2014-2017) for every Bay-Area bikeshare region
WITH trips_enriched AS (
  SELECT
    r.name                                         AS region_name,
    t.trip_id,
    t.duration_sec                                 AS ride_duration_sec,
    t.start_date                                   AS ride_start_time,
    s.name                                         AS starting_station,
    t.member_gender,
    ROW_NUMBER() OVER (PARTITION BY r.region_id
                       ORDER BY t.start_date DESC, t.trip_id DESC) AS rn
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`        AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
       ON t.start_station_id = CAST(s.station_id AS INT64)
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`      AS r
       ON s.region_id = r.region_id
  WHERE EXTRACT(YEAR FROM t.start_date) BETWEEN 2014 AND 2017
)

SELECT
  region_name,
  trip_id,
  ride_duration_sec,
  ride_start_time,
  starting_station,
  member_gender
FROM trips_enriched
WHERE rn = 1
ORDER BY region_name;
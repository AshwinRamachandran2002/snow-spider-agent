-- Latest bicycle trip (2014-2017) for every Bay-Area bike-share region
WITH trips_by_region AS (
  SELECT
    r.name                                                AS region,
    t.trip_id,
    t.duration_sec                                        AS ride_duration_sec,
    t.start_date                                          AS trip_start_time,
    t.start_station_name                                  AS start_station,
    t.member_gender                                       AS rider_gender,
    ROW_NUMBER() OVER (PARTITION BY r.name
                       ORDER BY t.start_date DESC)        AS rn
  FROM  `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`        AS t
  JOIN  `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
        ON CAST(t.start_station_id AS STRING) = s.station_id
  JOIN  `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`      AS r
        ON s.region_id = r.region_id
  WHERE EXTRACT(YEAR FROM t.start_date) BETWEEN 2014 AND 2017
)

SELECT
  region,
  trip_id,
  ride_duration_sec,
  trip_start_time,
  start_station,
  rider_gender
FROM trips_by_region
WHERE rn = 1
ORDER BY region;
WITH latest_trip_per_region AS (
  SELECT
    r.name                                     AS region_name,
    t.trip_id,
    t.duration_sec,
    t.start_date,
    t.start_station_name,
    t.member_gender,
    ROW_NUMBER() OVER (
        PARTITION BY r.region_id
        ORDER BY t.start_date DESC, t.trip_id DESC
    )                                          AS rn
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`           AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`    AS s
       ON CAST(t.start_station_id AS STRING) = s.station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`         AS r
       ON s.region_id = r.region_id
  WHERE t.start_date BETWEEN TIMESTAMP('2014-01-01')
                        AND TIMESTAMP('2017-12-31 23:59:59')
)

SELECT
  region_name,
  trip_id,
  duration_sec,
  start_date,
  start_station_name,
  member_gender
FROM latest_trip_per_region
WHERE rn = 1
ORDER BY region_name;
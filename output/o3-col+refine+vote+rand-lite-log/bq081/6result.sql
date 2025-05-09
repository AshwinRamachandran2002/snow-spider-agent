SELECT
  r.name                                AS region_name,
  t.trip_id,
  t.duration_sec,
  t.start_date,
  t.start_station_name,
  t.member_gender
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`        AS t
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON t.start_station_id = SAFE_CAST(s.station_id AS INT64)
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`      AS r
  ON s.region_id = r.region_id
WHERE t.start_date BETWEEN TIMESTAMP('2014-01-01') AND TIMESTAMP('2017-12-31 23:59:59')
QUALIFY ROW_NUMBER() OVER (PARTITION BY r.region_id ORDER BY t.start_date DESC) = 1;
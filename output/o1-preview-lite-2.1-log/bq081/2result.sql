SELECT
  r.name AS Region_Name,
  t.trip_id AS Trip_ID,
  t.duration_sec AS Duration_Seconds,
  t.start_date AS Start_Time,
  t.start_station_name AS Start_Station_Name,
  t.member_gender AS Rider_Gender
FROM (
  SELECT
    t.*,
    s.region_id,
    ROW_NUMBER() OVER (PARTITION BY s.region_id ORDER BY t.start_date DESC) AS rn
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  JOIN
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON
    CAST(t.start_station_id AS STRING) = s.station_id
  WHERE
    DATE(t.start_date) BETWEEN '2014-01-01' AND '2017-12-31'
) AS t
JOIN
  `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS r
ON
  t.region_id = r.region_id
WHERE
  t.rn = 1;
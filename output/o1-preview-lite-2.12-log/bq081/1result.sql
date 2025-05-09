SELECT
  region_data.region_name AS Region_Name,
  region_data.trip_id AS Trip_ID,
  region_data.duration_sec AS Duration_Seconds,
  region_data.start_date AS Start_Time,
  region_data.start_station_name AS Start_Station_Name,
  region_data.member_gender AS Rider_Gender
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
      ORDER BY t.start_date DESC
    ) AS row_num
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` s
    ON t.start_station_id = CAST(s.station_id AS INT64)
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` r
    ON s.region_id = r.region_id
  WHERE t.start_date BETWEEN '2014-01-01' AND '2017-12-31'
    AND s.region_id IS NOT NULL
) AS region_data
WHERE region_data.row_num = 1;
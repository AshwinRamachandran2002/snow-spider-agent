-- Latest ride (2014‑2017) for each Bay‑Area Bike‑Share region
WITH trips_2014_17 AS (
  SELECT
    trip_id,
    duration_sec,
    start_date,
    start_station_name,
    CAST(start_station_id AS INT64) AS start_station_id,
    member_gender
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE start_date BETWEEN TIMESTAMP('2014-01-01') AND TIMESTAMP('2017-12-31 23:59:59')
),
stations AS (
  SELECT
    CAST(station_id AS INT64) AS station_id,
    region_id
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
  WHERE region_id IS NOT NULL
),
trips_with_region AS (
  SELECT
    t.*,
    s.region_id
  FROM trips_2014_17 t
  JOIN stations s
    ON t.start_station_id = s.station_id
),
ranked AS (
  SELECT
    region_id,
    trip_id,
    duration_sec,
    start_date,
    start_station_name,
    member_gender,
    ROW_NUMBER() OVER (PARTITION BY region_id
                       ORDER BY start_date DESC, trip_id DESC) AS rn
  FROM trips_with_region
)
SELECT
  r.name AS region_name,
  ranked.trip_id,
  ranked.duration_sec,
  ranked.start_date,
  ranked.start_station_name,
  ranked.member_gender
FROM ranked
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` r
  ON ranked.region_id = r.region_id
WHERE ranked.rn = 1
ORDER BY region_name;
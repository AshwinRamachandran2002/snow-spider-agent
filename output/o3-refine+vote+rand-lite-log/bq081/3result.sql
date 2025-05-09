-- Latest ride (by start_date) for every bike‑share region between 2014‑01‑01 and 2017‑12‑31
WITH trips_with_region AS (
  SELECT
    r.name                 AS region_name,
    r.region_id,
    t.trip_id,
    t.duration_sec,
    t.start_date,
    t.start_station_name,
    t.member_gender,
    ROW_NUMBER() OVER (
      PARTITION BY r.region_id
      ORDER BY t.start_date DESC, t.trip_id DESC   -- tie‑breaker on trip_id
    ) AS rn
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`          AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`  AS s
       ON CAST(t.start_station_id AS STRING) = s.station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`       AS r
       ON s.region_id = r.region_id
  WHERE t.start_date BETWEEN '2014-01-01' AND '2017-12-31 23:59:59'
)

SELECT
  region_name,
  trip_id,
  duration_sec,
  start_date,
  start_station_name,
  member_gender
FROM trips_with_region
WHERE rn = 1          -- keep only the latest ride per region
ORDER BY region_name;
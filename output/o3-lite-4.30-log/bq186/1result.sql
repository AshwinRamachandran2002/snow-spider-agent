WITH sf_trips AS (
  SELECT
    FORMAT_DATE('%Y%m', DATE(t.start_date)) AS year_month,
    t.start_date,
    t.duration_sec / 60.0 AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips` AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s
    ON t.start_station_id = s.station_id
  WHERE s.landmark = 'San Francisco'
),
ranked AS (
  SELECT
    year_month,
    duration_min,
    start_date,
    ROW_NUMBER() OVER (PARTITION BY year_month ORDER BY start_date ASC)  AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY year_month ORDER BY start_date DESC) AS rn_last
  FROM sf_trips
)
SELECT
  year_month,
  ROUND(MAX(IF(rn_first = 1, duration_min, NULL)), 4) AS first_trip_duration_min,
  ROUND(MAX(IF(rn_last  = 1, duration_min, NULL)), 4) AS last_trip_duration_min,
  ROUND(MAX(duration_min), 4)                         AS max_trip_duration_min,
  ROUND(MIN(duration_min), 4)                         AS min_trip_duration_min
FROM ranked
GROUP BY year_month
ORDER BY year_month;
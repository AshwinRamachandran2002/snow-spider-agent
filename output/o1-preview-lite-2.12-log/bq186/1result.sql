WITH trips AS (
  SELECT
    FORMAT_DATE('%Y%m', DATE(start_date)) AS year_month,
    start_date,
    duration_sec / 60.0 AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
),
first_trips AS (
  SELECT
    year_month,
    duration_min AS first_trip_duration_minutes
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY year_month ORDER BY start_date ASC) AS rn
    FROM trips
  )
  WHERE rn = 1
),
last_trips AS (
  SELECT
    year_month,
    duration_min AS last_trip_duration_minutes
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY year_month ORDER BY start_date DESC) AS rn
    FROM trips
  )
  WHERE rn = 1
),
max_min_trips AS (
  SELECT
    year_month,
    MAX(duration_min) AS highest_trip_duration_minutes,
    MIN(duration_min) AS lowest_trip_duration_minutes
  FROM trips
  GROUP BY year_month
)
SELECT
  m.year_month,
  ROUND(f.first_trip_duration_minutes, 4) AS first_trip_duration_minutes,
  ROUND(l.last_trip_duration_minutes, 4) AS last_trip_duration_minutes,
  ROUND(m.highest_trip_duration_minutes, 4) AS highest_trip_duration_minutes,
  ROUND(m.lowest_trip_duration_minutes, 4) AS lowest_trip_duration_minutes
FROM max_min_trips m
JOIN first_trips f ON m.year_month = f.year_month
JOIN last_trips l ON m.year_month = l.year_month
ORDER BY m.year_month;
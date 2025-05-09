WITH trips AS (
  SELECT
    duration_sec,
    start_date,
    FORMAT_DATE('%Y-%m', DATE(start_date)) AS Month
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
  WHERE duration_sec > 0
),
first_trip AS (
  SELECT
    Month,
    ROUND(duration_sec / 60, 4) AS first_trip_duration_minutes
  FROM trips
  QUALIFY ROW_NUMBER() OVER (PARTITION BY Month ORDER BY start_date ASC) = 1
),
last_trip AS (
  SELECT
    Month,
    ROUND(duration_sec / 60, 4) AS last_trip_duration_minutes
  FROM trips
  QUALIFY ROW_NUMBER() OVER (PARTITION BY Month ORDER BY start_date DESC) = 1
),
duration_agg AS (
  SELECT
    Month,
    ROUND(MAX(duration_sec) / 60, 4) AS highest_duration_minutes,
    ROUND(MIN(duration_sec) / 60, 4) AS lowest_duration_minutes
  FROM trips
  GROUP BY Month
)
SELECT
  first_trip.Month,
  first_trip.first_trip_duration_minutes,
  last_trip.last_trip_duration_minutes,
  duration_agg.highest_duration_minutes,
  duration_agg.lowest_duration_minutes
FROM first_trip
JOIN last_trip USING (Month)
JOIN duration_agg USING (Month)
ORDER BY first_trip.Month;
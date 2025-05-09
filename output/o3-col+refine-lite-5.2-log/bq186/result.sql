-- For every year‑month (YYYYMM) compute:
--   • first  trip duration (minutes) – earliest start_date
--   • last   trip duration (minutes) – latest  start_date
--   • highest trip duration (minutes) – max duration that month
--   • lowest  trip duration (minutes) – min duration that month
-- Results are rounded to two decimals and ordered by year‑month.

WITH trips AS (
  SELECT
    FORMAT_DATE('%Y%m', DATE(start_date)) AS yyyymm,
    duration_sec,
    start_date
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
)

SELECT
  yyyymm,
  ROUND( (ARRAY_AGG(duration_sec ORDER BY start_date ASC  LIMIT 1)[OFFSET(0)]) / 60, 2) AS first_trip_minutes,
  ROUND( (ARRAY_AGG(duration_sec ORDER BY start_date DESC LIMIT 1)[OFFSET(0)]) / 60, 2) AS last_trip_minutes,
  ROUND( MAX(duration_sec) / 60, 2)                                                     AS highest_trip_minutes,
  ROUND( MIN(duration_sec) / 60, 2)                                                     AS lowest_trip_minutes
FROM trips
GROUP BY yyyymm
ORDER BY yyyymm;
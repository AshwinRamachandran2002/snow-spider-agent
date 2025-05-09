WITH trips AS (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', start_date) AS ym,
    start_date,
    duration_sec / 60.0                  AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY ym ORDER BY start_date)      AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY ym ORDER BY start_date DESC) AS rn_last
  FROM trips
)
SELECT
  ym,
  MAX(IF(rn_first = 1, duration_min, NULL)) AS first_trip_duration_min,
  MAX(IF(rn_last  = 1, duration_min, NULL)) AS last_trip_duration_min,
  MAX(duration_min)                         AS highest_trip_duration_min,
  MIN(duration_min)                         AS lowest_trip_duration_min
FROM ranked
GROUP BY ym
ORDER BY ym;
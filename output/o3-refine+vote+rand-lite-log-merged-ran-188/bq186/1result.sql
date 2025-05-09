-- First / last / highest / lowest trip duration (minutes) for every year‑month
WITH trips AS (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', start_date)            AS yyyymm,          -- e.g. 201409
    duration_sec / 60.0                             AS duration_min,    -- minutes (decimal)
    start_date,
    trip_id                                         -- tie‑breaker
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY yyyymm
                       ORDER BY start_date, trip_id)            AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY yyyymm
                       ORDER BY start_date DESC, trip_id DESC)  AS rn_last
  FROM trips
)

SELECT
  yyyymm,
  MAX(CASE WHEN rn_first = 1 THEN duration_min END)  AS first_trip_duration_min,
  MAX(CASE WHEN rn_last  = 1 THEN duration_min END)  AS last_trip_duration_min,
  MAX(duration_min)                                  AS highest_trip_duration_min,
  MIN(duration_min)                                  AS lowest_trip_duration_min
FROM ranked
GROUP BY yyyymm
ORDER BY yyyymm;
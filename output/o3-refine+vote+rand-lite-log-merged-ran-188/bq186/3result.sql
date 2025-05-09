WITH trips AS (
  SELECT
    FORMAT_DATE('%Y%m', DATE(start_date))                         AS year_month,
    duration_sec / 60.0                                           AS duration_min,
    start_date,
    trip_id
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
),
ranked AS (
  SELECT
    year_month,
    duration_min,
    ROW_NUMBER() OVER (PARTITION BY year_month
                       ORDER BY start_date ASC, trip_id ASC)      AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY year_month
                       ORDER BY start_date DESC, trip_id DESC)    AS rn_last
  FROM trips
)
SELECT
  year_month,
  MAX(CASE WHEN rn_first = 1 THEN duration_min END)  AS first_trip_duration_min,
  MAX(CASE WHEN rn_last  = 1 THEN duration_min END)  AS last_trip_duration_min,
  MAX(duration_min)                                  AS highest_trip_duration_min,
  MIN(duration_min)                                  AS lowest_trip_duration_min
FROM ranked
GROUP BY year_month
ORDER BY year_month;
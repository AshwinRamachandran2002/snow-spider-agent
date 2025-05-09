WITH sf_trips AS (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', t.start_date)               AS yyyymm,
    t.start_date,
    t.duration_sec / 60.0                                AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`   AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s
        ON t.start_station_id = s.station_id
  WHERE s.landmark = 'San Francisco'          -- keep only trips that start in SF
),

month_stats AS (
  SELECT
    yyyymm,
    ARRAY_AGG(duration_min ORDER BY start_date ASC  LIMIT 1)[OFFSET(0)] AS first_trip_min,
    ARRAY_AGG(duration_min ORDER BY start_date DESC LIMIT 1)[OFFSET(0)] AS last_trip_min,
    MAX(duration_min)                                                   AS highest_trip_min,
    MIN(duration_min)                                                   AS lowest_trip_min
  FROM sf_trips
  GROUP BY yyyymm
)

SELECT
  yyyymm,
  first_trip_min,
  last_trip_min,
  highest_trip_min,
  lowest_trip_min
FROM month_stats
ORDER BY yyyymm;
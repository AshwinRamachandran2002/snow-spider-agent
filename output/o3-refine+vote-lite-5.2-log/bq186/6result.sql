WITH sf_trips AS (
  -- keep only trips that START in San Francisco
  SELECT
    FORMAT_DATE('%Y%m', DATE(t.start_date))      AS ym,          -- year‑month key
    t.start_date,
    t.duration_sec / 60.0                        AS duration_min -- minutes (float)
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`   AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s
    ON t.start_station_id = s.station_id
  WHERE s.landmark = 'San Francisco'
),
ranked AS (
  SELECT
    ym,
    duration_min,
    start_date,
    ROW_NUMBER() OVER (PARTITION BY ym ORDER BY start_date ASC)  AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY ym ORDER BY start_date DESC) AS rn_last
  FROM sf_trips
)

SELECT
  ym,
  ROUND(MAX(CASE WHEN rn_first = 1 THEN duration_min END), 4) AS first_trip_duration_min,
  ROUND(MAX(CASE WHEN rn_last  = 1 THEN duration_min END), 4) AS last_trip_duration_min,
  ROUND(MAX(duration_min), 4)                                AS highest_trip_duration_min,
  ROUND(MIN(duration_min), 4)                                AS lowest_trip_duration_min
FROM ranked
GROUP BY ym
ORDER BY ym;
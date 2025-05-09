WITH qualified AS (
  SELECT
    ROUND(trip_seconds / 60.0) AS dur_minutes,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND ROUND(trip_seconds / 60.0) BETWEEN 1 AND 50
),
bucketed AS (
  SELECT
    dur_minutes,
    fare,
    NTILE(10) OVER (ORDER BY dur_minutes) AS decile
  FROM qualified
),
summary AS (
  SELECT
    decile,
    MIN(dur_minutes) AS min_dur,
    MAX(dur_minutes) AS max_dur,
    COUNT(*)         AS total_trips,
    AVG(fare)        AS avg_fare
  FROM bucketed
  GROUP BY decile
)
SELECT
  FORMAT('%02dm to %02dm', CAST(min_dur AS INT64), CAST(max_dur AS INT64)) AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare)                                                AS average_fare
FROM summary
ORDER BY CAST(min_dur AS INT64);
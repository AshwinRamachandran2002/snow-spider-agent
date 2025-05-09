SELECT
  CONCAT(
    LPAD(CAST(min_minute AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(max_minute AS STRING), 2, '0'), 'm'
  )                           AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare)    AS average_fare
FROM (
  SELECT
    ntile,
    MIN(minutes_rounded)                AS min_minute,
    MAX(minutes_rounded)                AS max_minute,
    COUNT(*)                            AS total_trips,
    AVG(fare)                           AS avg_fare
  FROM (
    SELECT
      ROUND(trip_seconds / 60.0)                      AS minutes_rounded,
      fare,
      NTILE(10) OVER (ORDER BY ROUND(trip_seconds / 60.0)) AS ntile
    FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
    WHERE trip_seconds BETWEEN 60 AND 3000   -- 1–50 minutes
      AND fare IS NOT NULL                   -- valid fares only
  )
  GROUP BY ntile
)
ORDER BY min_minute;
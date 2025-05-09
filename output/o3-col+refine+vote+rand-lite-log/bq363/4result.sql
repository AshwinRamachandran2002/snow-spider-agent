WITH eligible AS (
  SELECT
    ROUND(trip_seconds / 60.0) AS trip_minutes,
    fare,
    NTILE(10) OVER (ORDER BY ROUND(trip_seconds / 60.0)) AS tile
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
        trip_seconds BETWEEN 60 AND 3000   -- 1-50 minutes only
    AND fare IS NOT NULL                   -- required for AVG()
)
SELECT
  CONCAT(
    LPAD(CAST(MIN(trip_minutes) AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(MAX(trip_minutes) AS STRING), 2, '0'), 'm'
  )                           AS time_range,
  COUNT(*)                    AS total_trips,
  FORMAT('%.2f', AVG(fare))   AS average_fare
FROM eligible
GROUP BY tile
ORDER BY MIN(trip_minutes);
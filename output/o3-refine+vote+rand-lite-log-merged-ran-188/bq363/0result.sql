WITH filtered AS (
  -- Keep trips whose duration rounds to 1-50 minutes
  SELECT
    ROUND(trip_seconds / 60.0) AS rounded_min,
    fare,
    NTILE(10) OVER (ORDER BY ROUND(trip_seconds / 60.0)) AS quantile
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE ROUND(trip_seconds / 60.0) BETWEEN 1 AND 50
)
SELECT
  LPAD(CAST(MIN(rounded_min) AS STRING), 2, '0') || 'm to ' ||
  LPAD(CAST(MAX(rounded_min) AS STRING), 2, '0') || 'm' AS time_range,
  COUNT(*)                                   AS total_trips,
  FORMAT('%.2f', AVG(fare))                  AS average_fare
FROM filtered
GROUP BY quantile
ORDER BY MIN(rounded_min);
WITH eligible_trips AS (
  SELECT
    trip_seconds,
    fare,
    NTILE(6) OVER (ORDER BY trip_seconds / 60.0) AS quantile_group
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds > 0            -- keep only positive-length trips
    AND trip_seconds <= 3600        -- limit to 0–60 minutes
)

SELECT
  quantile_group,
  MIN(ROUND(trip_seconds / 60.0)) AS min_duration_minutes,
  MAX(ROUND(trip_seconds / 60.0)) AS max_duration_minutes,
  COUNT(*)                         AS total_trips,
  AVG(fare)                        AS avg_fare
FROM eligible_trips
GROUP BY quantile_group
ORDER BY quantile_group;
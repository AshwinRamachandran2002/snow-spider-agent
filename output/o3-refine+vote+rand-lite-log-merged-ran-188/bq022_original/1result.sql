WITH filtered AS (
  SELECT
    unique_key,
    fare,
    trip_seconds,
    trip_seconds / 60.0 AS trip_minutes
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND trip_seconds BETWEEN 0 AND 3600          -- 0‑60 minutes
),

quantiles AS (
  SELECT
    NTILE(6) OVER (ORDER BY trip_minutes, unique_key) AS quantile_group,
    trip_minutes,
    fare
  FROM filtered
)

SELECT
  quantile_group,
  ROUND(MIN(trip_minutes)) AS min_duration_minutes,
  ROUND(MAX(trip_minutes)) AS max_duration_minutes,
  COUNT(*)                AS trip_count,
  ROUND(AVG(fare), 4)     AS avg_fare
FROM quantiles
GROUP BY quantile_group
ORDER BY quantile_group;
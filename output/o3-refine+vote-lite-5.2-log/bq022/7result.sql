WITH filtered AS (
  -- Keep only trips whose duration is between 0 and 60 minutes
  SELECT
    trip_seconds,
    fare,
    ROUND(trip_seconds / 60.0) AS duration_minutes_rounded
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND trip_seconds > 0                          -- positive trips only
    AND trip_seconds <= 60 * 60                  -- ≤ 60 minutes
    AND fare IS NOT NULL                         -- needed for avg(fare)
),
hexiles AS (
  -- Divide the filtered trips into six equal‑sized quantile groups
  SELECT
    *,
    NTILE(6) OVER (ORDER BY trip_seconds) AS quantile_group
  FROM filtered
)
SELECT
  quantile_group,                                           -- 1 … 6
  MIN(duration_minutes_rounded) AS min_trip_minutes,
  MAX(duration_minutes_rounded) AS max_trip_minutes,
  COUNT(*)                         AS total_trips,
  ROUND(AVG(fare), 4)              AS avg_fare
FROM hexiles
GROUP BY quantile_group
ORDER BY quantile_group;
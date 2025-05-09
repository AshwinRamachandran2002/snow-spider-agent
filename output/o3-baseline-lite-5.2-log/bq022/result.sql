WITH filtered AS (
  SELECT 
    trip_seconds / 60.0 AS duration_min,   -- duration in minutes
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds > 0                      -- exclude 0‑second trips
    AND trip_seconds <= 60 * 60              -- keep trips up to 60 minutes
),
quantiled AS (
  SELECT
    NTILE(6) OVER (ORDER BY duration_min) AS quantile_group,  -- six equal groups
    duration_min,
    fare
  FROM filtered
)
SELECT
  quantile_group,
  ROUND(MIN(duration_min)) AS min_duration_min,
  ROUND(MAX(duration_min)) AS max_duration_min,
  COUNT(*)                 AS total_trips,
  ROUND(AVG(fare), 4)      AS avg_fare
FROM quantiled
GROUP BY quantile_group
ORDER BY quantile_group;
WITH filtered_trips AS (
  SELECT
    trip_seconds / 60.0 AS duration_min,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds BETWEEN 1 AND 3600            -- keep trips >0 sec and ≤60 min
    AND fare IS NOT NULL                           -- exclude rows without a fare
),
hexiles AS (
  SELECT
    NTILE(6) OVER (ORDER BY duration_min) AS quantile_grp,  -- 6‑quantile buckets
    duration_min,
    fare
  FROM filtered_trips
)
SELECT
  quantile_grp                             AS quantile_group,
  ROUND(MIN(duration_min))  AS min_trip_duration_minutes,
  ROUND(MAX(duration_min))  AS max_trip_duration_minutes,
  COUNT(*)                  AS total_trips,
  ROUND(AVG(fare), 4)       AS avg_fare
FROM hexiles
GROUP BY quantile_group
ORDER BY quantile_group;
WITH filtered AS (
  -- keep only trips whose duration is between 0 and 60 minutes
  SELECT
    trip_seconds / 60.0 AS duration_minutes,      -- convert to minutes
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds > 0
    AND trip_seconds <= 60 * 60                  -- ≤ 60 minutes
),
sextiles AS (
  -- assign each trip to one of six equal‑sized quantile groups
  SELECT
    *,
    NTILE(6) OVER (ORDER BY duration_minutes) AS quantile
  FROM filtered
)
SELECT
  quantile                                            AS duration_quantile,
  ROUND(MIN(duration_minutes))                        AS min_duration_minutes,
  ROUND(MAX(duration_minutes))                        AS max_duration_minutes,
  COUNT(*)                                            AS total_trips,
  ROUND(AVG(fare), 4)                                 AS average_fare
FROM sextiles
GROUP BY quantile
ORDER BY quantile;
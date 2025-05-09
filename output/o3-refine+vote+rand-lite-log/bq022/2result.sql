-- Six‑quantile summary of taxi trips lasting between 0 and 60 minutes
WITH filtered AS (
  SELECT
    trip_seconds,
    fare
  FROM
    `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    trip_seconds > 0                    -- positive duration
    AND trip_seconds <= 3600            -- up to 60 minutes
    AND fare IS NOT NULL                -- keep rows with a recorded fare
),
hexiled AS (
  SELECT
    NTILE(6) OVER (ORDER BY trip_seconds) AS quantile,  -- 6 equal groups
    trip_seconds,
    fare
  FROM
    filtered
)
SELECT
  quantile                                  AS duration_quantile,
  CAST(ROUND(MIN(trip_seconds) / 60.0) AS INT64) AS min_trip_minutes,
  CAST(ROUND(MAX(trip_seconds) / 60.0) AS INT64) AS max_trip_minutes,
  COUNT(*)                                  AS total_trips,
  AVG(fare)                                 AS avg_fare
FROM
  hexiled
GROUP BY
  duration_quantile
ORDER BY
  duration_quantile;
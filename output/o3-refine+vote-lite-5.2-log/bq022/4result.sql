-- Six‑quantile (hexile) profile of trips that lasted from 0‑60 minutes
WITH filtered AS (   -- keep only clean durations inside the requested window
  SELECT
    trip_seconds,
    trip_seconds / 60.0 AS trip_minutes,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND trip_seconds > 0
    AND trip_seconds <= 3600            -- 0‑60 minutes
),
hexiled AS (         -- assign each trip to one of six equal‑count duration bins
  SELECT
    *,
    NTILE(6) OVER (ORDER BY trip_minutes) AS hexile
  FROM filtered
)
SELECT
  hexile                         AS quantile_group,
  ROUND(MIN(trip_minutes))       AS min_trip_minutes,
  ROUND(MAX(trip_minutes))       AS max_trip_minutes,
  COUNT(*)                       AS total_trips,
  ROUND(AVG(fare), 4)            AS avg_fare
FROM hexiled
GROUP BY quantile_group
ORDER BY quantile_group;
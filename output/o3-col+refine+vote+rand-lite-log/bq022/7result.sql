-- Trip-duration quantiles (0–60 min): min/max rounded minutes, trip count, avg fare
WITH filtered AS (
  SELECT
    ROUND(trip_seconds / 60.0)                       AS trip_minutes,       -- duration (nearest minute)
    fare,
    NTILE(6) OVER (ORDER BY trip_seconds)            AS quantile            -- 6 equal-sized groups
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds BETWEEN 1 AND 3600                                    -- keep trips >0 sec and ≤60 min
)
SELECT
  quantile,                                           -- 1–6
  MIN(trip_minutes)  AS min_trip_minutes,
  MAX(trip_minutes)  AS max_trip_minutes,
  COUNT(*)          AS total_trips,
  ROUND(AVG(fare), 4) AS average_fare                 -- round to 4 decimals
FROM filtered
GROUP BY quantile
ORDER BY quantile;
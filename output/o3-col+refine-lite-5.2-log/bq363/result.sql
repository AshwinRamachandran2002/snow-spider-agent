-- Ten equal‑sized quantiles of 1‑‑50‑minute taxi trips:
-- time range (zero‑padded), total trips, and average fare (2 decimals)
WITH trip_minutes AS (
  SELECT
    ROUND(trip_seconds / 60.0, 0) AS rounded_min,
    fare
  FROM
    `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    trip_seconds BETWEEN 60 AND 3000         -- keep 1‑50‑minute trips
),
quantiled AS (
  SELECT
    NTILE(10) OVER (ORDER BY rounded_min) AS decile,
    rounded_min,
    fare
  FROM
    trip_minutes
),
stats AS (
  SELECT
    decile,
    MIN(rounded_min) AS lower_bound,
    MAX(rounded_min) AS upper_bound,
    COUNT(*)         AS total_trips,
    AVG(fare)        AS avg_fare
  FROM
    quantiled
  GROUP BY
    decile
)
SELECT
  FORMAT('%02dm to %02dm',
         CAST(lower_bound AS INT64),
         CAST(upper_bound AS INT64))          AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare)                    AS average_fare
FROM
  stats
ORDER BY
  lower_bound;
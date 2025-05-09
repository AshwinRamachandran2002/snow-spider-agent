SELECT
  CONCAT(
    CAST(MIN(rounded_trip_minutes) AS STRING),
    'm to ',
    CAST(MAX(rounded_trip_minutes) AS STRING),
    'm'
  ) AS Time_range,
  COUNT(*) AS Total_trips,
  ROUND(AVG(fare), 2) AS Average_fare
FROM (
  SELECT
    *,
    ROUND(CAST(trip_seconds AS FLOAT64) / 60) AS rounded_trip_minutes,
    NTILE(10) OVER (ORDER BY ROUND(CAST(trip_seconds AS FLOAT64) / 60)) AS quantile_group
  FROM
    `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    trip_seconds IS NOT NULL
    AND trip_seconds > 0
    AND fare IS NOT NULL
    AND fare > 0
    AND ROUND(CAST(trip_seconds AS FLOAT64) / 60) BETWEEN 1 AND 50
)
GROUP BY
  quantile_group
ORDER BY
  MIN(rounded_trip_minutes);
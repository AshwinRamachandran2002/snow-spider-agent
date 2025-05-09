SELECT
  Quantile_Group,
  MIN(trip_minutes) AS Min_Trip_Duration_Minutes,
  MAX(trip_minutes) AS Max_Trip_Duration_Minutes,
  COUNT(*) AS Total_Number_of_Trips,
  ROUND(AVG(fare), 4) AS Average_Fare
FROM (
  SELECT
    trip_minutes,
    fare,
    NTILE(6) OVER (ORDER BY trip_seconds) AS Quantile_Group
  FROM (
    SELECT
      trip_seconds,
      ROUND(trip_seconds / 60) AS trip_minutes,
      fare
    FROM
      `bigquery-public-data.chicago_taxi_trips.taxi_trips`
    WHERE
      trip_seconds > 0
      AND trip_seconds <= 3600
      AND fare IS NOT NULL
      AND fare > 0
  )
)
GROUP BY
  Quantile_Group
ORDER BY
  Quantile_Group;
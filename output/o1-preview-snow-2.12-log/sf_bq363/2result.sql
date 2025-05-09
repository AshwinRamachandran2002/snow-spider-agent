SELECT
  'Quantile ' || quantile || ' (' || MIN(trip_duration_minutes) || '-' || MAX(trip_duration_minutes) || ' minutes)' AS "Trip_Duration_Minutes_Quantile",
  COUNT(*) AS "Total_Number_of_Trips",
  ROUND(AVG("fare"), 4) AS "Average_Fare"
FROM (
  SELECT
    CASE
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 1 AND 5 THEN 1
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 6 AND 10 THEN 2
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 11 AND 15 THEN 3
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 16 AND 20 THEN 4
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 21 AND 25 THEN 5
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 26 AND 30 THEN 6
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 31 AND 35 THEN 7
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 36 AND 40 THEN 8
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 41 AND 45 THEN 9
      WHEN ROUND("trip_seconds" / 60.0) BETWEEN 46 AND 50 THEN 10
    END AS quantile,
    "fare",
    ROUND("trip_seconds" / 60.0) AS trip_duration_minutes
  FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
  WHERE
    "trip_seconds" IS NOT NULL AND "trip_seconds" > 0
    AND "fare" IS NOT NULL AND "fare" > 0
    AND ROUND("trip_seconds" / 60.0) BETWEEN 1 AND 50
) quantiles
GROUP BY quantile
ORDER BY quantile;
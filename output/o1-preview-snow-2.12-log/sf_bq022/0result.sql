SELECT
  'Q' || quantile AS "Quantile",
  ROUND(MIN("trip_seconds") / 60) AS "Min_Trip_Duration_Minutes",
  ROUND(MAX("trip_seconds") / 60) AS "Max_Trip_Duration_Minutes",
  COUNT(*) AS "Total_Trips",
  ROUND(AVG("fare"), 4) AS "Average_Fare"
FROM (
  SELECT
    "trip_seconds",
    "fare",
    NTILE(6) OVER (ORDER BY "trip_seconds") AS quantile
  FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
  WHERE "trip_seconds" > 0
    AND "trip_seconds" <= 3600
    AND "fare" IS NOT NULL
) sub
GROUP BY quantile
ORDER BY quantile;
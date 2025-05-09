SELECT
   'Q' || quantile AS "Quantile",
   MIN(ROUND("trip_seconds" / 60.0)) AS "Min_Trip_Duration_Minutes",
   MAX(ROUND("trip_seconds" / 60.0)) AS "Max_Trip_Duration_Minutes",
   COUNT(*) AS "Total_Trips",
   ROUND(AVG("trip_total"), 4) AS "Average_Fare"
FROM
   (
    SELECT
       "trip_seconds",
       "trip_total",
       NTILE(6) OVER (ORDER BY "trip_seconds") AS quantile
    FROM
       CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE
       "trip_seconds" > 0
       AND "trip_seconds" <= 3600
       AND "trip_total" IS NOT NULL
   ) sub
GROUP BY
   quantile
ORDER BY
   quantile;
SELECT
  quantile_label AS "Trip_Duration_Minutes_Quantile",
  COUNT(*) AS "Total_Number_of_Trips",
  ROUND(AVG("fare"), 4) AS "Average_Fare"
FROM (
  SELECT
    ROUND("trip_seconds" / 60.0) AS trip_minutes,
    "fare",
    CASE
      WHEN trip_minutes BETWEEN 1 AND 5 THEN 'Quantile 1 (1-5 minutes)'
      WHEN trip_minutes BETWEEN 6 AND 10 THEN 'Quantile 2 (6-10 minutes)'
      WHEN trip_minutes BETWEEN 11 AND 15 THEN 'Quantile 3 (11-15 minutes)'
      WHEN trip_minutes BETWEEN 16 AND 20 THEN 'Quantile 4 (16-20 minutes)'
      WHEN trip_minutes BETWEEN 21 AND 25 THEN 'Quantile 5 (21-25 minutes)'
      WHEN trip_minutes BETWEEN 26 AND 30 THEN 'Quantile 6 (26-30 minutes)'
      WHEN trip_minutes BETWEEN 31 AND 35 THEN 'Quantile 7 (31-35 minutes)'
      WHEN trip_minutes BETWEEN 36 AND 40 THEN 'Quantile 8 (36-40 minutes)'
      WHEN trip_minutes BETWEEN 41 AND 45 THEN 'Quantile 9 (41-45 minutes)'
      WHEN trip_minutes BETWEEN 46 AND 50 THEN 'Quantile 10 (46-50 minutes)'
    END AS quantile_label
  FROM
    "CHICAGO"."CHICAGO_TAXI_TRIPS"."TAXI_TRIPS"
  WHERE
    "trip_seconds" IS NOT NULL
    AND "trip_seconds" > 0
    AND ROUND("trip_seconds" / 60.0) BETWEEN 1 AND 50
) sub
GROUP BY
  quantile_label
ORDER BY
  quantile_label;
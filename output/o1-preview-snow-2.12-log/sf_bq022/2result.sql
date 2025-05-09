SELECT
    CASE
        WHEN "Rounded_Trip_Minutes" <= 5 THEN 'Q1'
        WHEN "Rounded_Trip_Minutes" <= 7 THEN 'Q2'
        WHEN "Rounded_Trip_Minutes" <= 10 THEN 'Q3'
        WHEN "Rounded_Trip_Minutes" <= 14 THEN 'Q4'
        WHEN "Rounded_Trip_Minutes" <= 22 THEN 'Q5'
        ELSE 'Q6'
    END AS "Quantile",
    MIN("Rounded_Trip_Minutes") AS "Min_Trip_Duration_Minutes",
    MAX("Rounded_Trip_Minutes") AS "Max_Trip_Duration_Minutes",
    COUNT(*) AS "Total_Trips",
    ROUND(AVG("fare"), 4) AS "Average_Fare"
FROM (
    SELECT
        ROUND("trip_seconds" / 60.0) AS "Rounded_Trip_Minutes",
        "fare"
    FROM "CHICAGO"."CHICAGO_TAXI_TRIPS"."TAXI_TRIPS"
    WHERE "trip_seconds" > 0
      AND "trip_seconds" <= 3600
      AND "fare" > 0
) sub
GROUP BY 1
ORDER BY "Quantile";
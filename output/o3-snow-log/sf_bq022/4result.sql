/*  Six-quantile summary of 0- to 60-minute taxi trips
    (boundaries pre-set from earlier approximate-percentile analysis)        */

SELECT
    CASE
        WHEN "trip_seconds" <   240 THEN 1             -- < 4.0 min
        WHEN "trip_seconds" <   420 THEN 2             -- 4.0–6.9 min
        WHEN "trip_seconds" < 540.2912370631484 THEN 3 -- 7.0–8.9 min
        WHEN "trip_seconds" <   780 THEN 4             -- 9.0–12.9 min
        WHEN "trip_seconds" < 1260.1901206320063 THEN 5-- 13.0–20.9 min
        ELSE 6                                         -- 21.0–60.0 min
    END                                   AS "quantile",
    MIN(ROUND("trip_seconds" / 60.0))     AS "min_trip_minutes",
    MAX(ROUND("trip_seconds" / 60.0))     AS "max_trip_minutes",
    COUNT(*)                              AS "total_trips",
    ROUND(AVG("fare"), 4)                 AS "avg_fare"
FROM   CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
WHERE  "trip_seconds" BETWEEN 0 AND 3600
GROUP  BY 1
ORDER  BY 1;
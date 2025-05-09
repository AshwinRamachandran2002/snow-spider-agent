SELECT
    z."borough",
    ROUND((COUNT(CASE WHEN y."tip_amount" = 0 THEN 1 END) * 100.0 / COUNT(*)), 4) AS "percentage_no_tip"
FROM
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" y
JOIN
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" z
ON
    y."pickup_location_id" = z."zone_id"
WHERE
    TO_TIMESTAMP_NTZ(y."pickup_datetime" / 1e6) >= '2016-01-01 00:00:00'
    AND TO_TIMESTAMP_NTZ(y."pickup_datetime" / 1e6) < '2016-01-08 00:00:00'
    AND y."dropoff_datetime" > y."pickup_datetime"
    AND y."passenger_count" > 0
    AND y."trip_distance" >= 0
    AND y."tip_amount" >= 0
    AND y."tolls_amount" >= 0
    AND y."mta_tax" >= 0
    AND y."fare_amount" >= 0
    AND y."total_amount" >= 0
    AND z."borough" IN ('Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island')
GROUP BY
    z."borough"
ORDER BY
    z."borough";
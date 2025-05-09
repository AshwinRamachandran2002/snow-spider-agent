SELECT 
    z."borough", 
    t."tip_category", 
    ROUND(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (PARTITION BY z."borough"), 4) AS "proportion"
FROM (
    SELECT 
        t.*, 
        CASE 
            WHEN "tip_rate" = 0 THEN 'no tip'
            WHEN "tip_rate" > 0 AND "tip_rate" <= 5 THEN 'Less than 5%'
            WHEN "tip_rate" > 5 AND "tip_rate" <= 10 THEN '5% to 10%'
            WHEN "tip_rate" > 10 AND "tip_rate" <= 15 THEN '10% to 15%'
            WHEN "tip_rate" > 15 AND "tip_rate" <= 20 THEN '15% to 20%'
            WHEN "tip_rate" > 20 AND "tip_rate" <= 25 THEN '20% to 25%'
            ELSE 'More than 25%'
        END AS "tip_category"
    FROM (
        SELECT 
            t.*, 
            CASE 
                WHEN ("total_amount" - "tip_amount") > 0 THEN ("tip_amount" / ("total_amount" - "tip_amount")) * 100
                ELSE 0
            END AS "tip_rate"
        FROM "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
        WHERE 
            TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1000000) >= '2016-01-01'
            AND TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1000000) < '2016-01-08'
            AND t."passenger_count" > 0
            AND t."dropoff_datetime" > t."pickup_datetime"
            AND t."trip_distance" >= 0
            AND t."tip_amount" >= 0
            AND t."tolls_amount" >= 0
            AND t."mta_tax" >= 0
            AND t."fare_amount" >= 0
            AND t."total_amount" >= 0
        ) t
    ) t
JOIN "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" z
    ON t."pickup_location_id" = z."zone_id"
WHERE z."borough" NOT IN ('EWR', 'Staten Island')
GROUP BY z."borough", t."tip_category"
ORDER BY z."borough", t."tip_category";
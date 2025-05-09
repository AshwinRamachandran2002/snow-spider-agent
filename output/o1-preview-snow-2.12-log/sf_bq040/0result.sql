SELECT
    sub."borough" AS "pickup_borough",
    CASE
        WHEN tip_percentage = 0 THEN '0%'
        WHEN tip_percentage > 0 AND tip_percentage <= 5 THEN 'up to 5%'
        WHEN tip_percentage > 5 AND tip_percentage <= 10 THEN '5% to 10%'
        WHEN tip_percentage > 10 AND tip_percentage <= 15 THEN '10% to 15%'
        WHEN tip_percentage > 15 AND tip_percentage <= 20 THEN '15% to 20%'
        WHEN tip_percentage > 20 AND tip_percentage <= 25 THEN '20% to 25%'
        WHEN tip_percentage > 25 THEN 'more than 25%'
    END AS "tip_percentage_category",
    ROUND(COUNT(*)::FLOAT / SUM(COUNT(*)) OVER (PARTITION BY sub."borough"), 4) AS "proportion_of_rides"
FROM (
    SELECT
        t."pickup_datetime",
        t."dropoff_datetime",
        t."passenger_count",
        t."trip_distance",
        t."tip_amount",
        t."tolls_amount",
        t."mta_tax",
        t."fare_amount",
        t."total_amount",
        t."pickup_location_id",
        z."borough",
        CASE
            WHEN (t."total_amount" - t."tip_amount") > 0 THEN
                (t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100
            ELSE 0
        END AS tip_percentage
    FROM "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
    JOIN "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" z
        ON t."pickup_location_id" = z."zone_id"
    WHERE
        TO_TIMESTAMP(t."pickup_datetime" / 1e6) >= TO_TIMESTAMP('2016-01-01', 'YYYY-MM-DD')
        AND TO_TIMESTAMP(t."pickup_datetime" / 1e6) < TO_TIMESTAMP('2016-01-08', 'YYYY-MM-DD')
        AND t."dropoff_datetime" > t."pickup_datetime"
        AND t."passenger_count" > 0
        AND t."trip_distance" >= 0
        AND t."tip_amount" >= 0
        AND t."tolls_amount" >= 0
        AND t."mta_tax" >= 0
        AND t."fare_amount" >= 0
        AND t."total_amount" >= 0
        AND z."borough" NOT IN ('EWR', 'Staten Island')
    ) sub
GROUP BY sub."borough", "tip_percentage_category"
ORDER BY sub."borough", "tip_percentage_category";
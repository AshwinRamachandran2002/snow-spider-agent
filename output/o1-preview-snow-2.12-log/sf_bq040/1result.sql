WITH trips AS (
    SELECT
        tt.*,
        tg."borough" AS pickup_borough,
        CASE
            WHEN (tt."total_amount" - tt."tip_amount") > 0 THEN 
                (tt."tip_amount" / (tt."total_amount" - tt."tip_amount")) * 100
            ELSE 0
        END AS tip_rate
    FROM
        "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" AS tt
    JOIN
        "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" AS tg
    ON
        tt."pickup_location_id" = tg."zone_id"
    WHERE
        TO_TIMESTAMP_NTZ(tt."pickup_datetime" / 1e6) >= '2016-01-01'
        AND TO_TIMESTAMP_NTZ(tt."pickup_datetime" / 1e6) < '2016-01-08'
        AND tg."zone_name" <> 'EWR'
        AND tg."borough" <> 'Staten Island'
        AND tt."dropoff_datetime" > tt."pickup_datetime"
        AND tt."passenger_count" > 0
        AND tt."trip_distance" >= 0
        AND tt."tip_amount" >= 0
        AND tt."tolls_amount" >= 0
        AND tt."mta_tax" >= 0
        AND tt."fare_amount" >= 0
        AND tt."total_amount" >= 0
),
trips_with_categories AS (
    SELECT
        *,
        CASE
            WHEN tip_rate = 0 THEN '0%'
            WHEN tip_rate > 0 AND tip_rate <= 5 THEN 'up to 5%'
            WHEN tip_rate > 5 AND tip_rate <= 10 THEN '5% to 10%'
            WHEN tip_rate > 10 AND tip_rate <= 15 THEN '10% to 15%'
            WHEN tip_rate > 15 AND tip_rate <= 20 THEN '15% to 20%'
            WHEN tip_rate > 20 AND tip_rate <= 25 THEN '20% to 25%'
            WHEN tip_rate > 25 THEN 'more than 25%'
            ELSE 'unknown'
        END AS tip_percentage_category
    FROM
        trips
),
trip_counts AS (
    SELECT
        pickup_borough,
        tip_percentage_category,
        COUNT(*) AS trips_in_category
    FROM
        trips_with_categories
    GROUP BY
        pickup_borough,
        tip_percentage_category
),
total_trip_counts AS (
    SELECT
        pickup_borough,
        SUM(trips_in_category) AS total_trips_in_borough
    FROM
        trip_counts
    GROUP BY
        pickup_borough
)
SELECT
    tc.pickup_borough AS PICKUP_BOROUGH,
    tc.tip_percentage_category AS TIP_PERCENTAGE_CATEGORY,
    ROUND((tc.trips_in_category * 1.0) / ttc.total_trips_in_borough, 4) AS PROPORTION_OF_RIDES
FROM
    trip_counts tc
JOIN
    total_trip_counts ttc
ON
    tc.pickup_borough = ttc.pickup_borough
ORDER BY
    tc.pickup_borough,
    tc.tip_percentage_category;
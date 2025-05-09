WITH filtered_trips AS (
    SELECT 
        z."borough" AS "pickup_borough",
        t."tip_amount",
        t."total_amount",
        (t."tip_amount" / NULLIF(t."total_amount" - t."tip_amount", 0)) * 100 AS "tip_rate"
    FROM
        "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
    JOIN
        "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" z
            ON t."pickup_location_id" = z."zone_id"
    WHERE
        TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6) >= '2016-01-01 00:00:00' 
        AND TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6) < '2016-01-08 00:00:00'
        AND t."dropoff_datetime" > t."pickup_datetime"
        AND t."passenger_count" > 0
        AND t."trip_distance" >= 0
        AND t."tip_amount" >= 0
        AND t."tolls_amount" >= 0
        AND t."mta_tax" >= 0
        AND t."fare_amount" >= 0
        AND t."total_amount" >= 0
        AND (t."total_amount" - t."tip_amount") > 0
        AND z."borough" NOT IN ('Staten Island', 'EWR')
),
categorized_tips AS (
    SELECT
        "pickup_borough",
        CASE
            WHEN "tip_amount" = 0 THEN '0%'
            WHEN "tip_rate" <= 5 THEN 'up to 5%'
            WHEN "tip_rate" > 5 AND "tip_rate" <= 10 THEN '5% to 10%'
            WHEN "tip_rate" > 10 AND "tip_rate" <= 15 THEN '10% to 15%'
            WHEN "tip_rate" > 15 AND "tip_rate" <= 20 THEN '15% to 20%'
            WHEN "tip_rate" > 20 AND "tip_rate" <= 25 THEN '20% to 25%'
            WHEN "tip_rate" > 25 THEN 'more than 25%'
            ELSE 'unknown'
        END AS "tip_percentage_category"
    FROM filtered_trips
)
SELECT
    "pickup_borough",
    "tip_percentage_category",
    ROUND(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (PARTITION BY "pickup_borough"), 4) AS "proportion_of_rides"
FROM categorized_tips
GROUP BY "pickup_borough", "tip_percentage_category"
ORDER BY "pickup_borough", "tip_percentage_category";
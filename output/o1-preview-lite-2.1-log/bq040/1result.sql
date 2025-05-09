WITH filtered_trips AS (
    SELECT 
        t.*,
        z.borough,
        (t.tip_amount / NULLIF(t.total_amount - t.tip_amount, 0)) * 100 AS tip_rate
    FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
    JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
        ON t.pickup_location_id = z.zone_id
    WHERE 
        t.pickup_datetime >= '2016-01-01' 
        AND t.pickup_datetime < '2016-01-08'
        AND t.dropoff_datetime > t.pickup_datetime
        AND t.passenger_count > 0
        AND t.trip_distance >= 0
        AND t.tip_amount >= 0
        AND t.tolls_amount >= 0
        AND t.mta_tax >= 0
        AND t.fare_amount >= 0
        AND t.total_amount >= 0
        AND t.total_amount > t.tip_amount
        AND z.borough NOT IN ('EWR', 'Staten Island')
),
categorized_trips AS (
    SELECT 
        borough,
        CASE 
            WHEN tip_rate = 0 THEN 'no tip'
            WHEN tip_rate > 0 AND tip_rate <= 5 THEN 'Less than 5%'
            WHEN tip_rate > 5 AND tip_rate <= 10 THEN '5% to 10%'
            WHEN tip_rate > 10 AND tip_rate <= 15 THEN '10% to 15%'
            WHEN tip_rate > 15 AND tip_rate <= 20 THEN '15% to 20%'
            WHEN tip_rate > 20 AND tip_rate <= 25 THEN '20% to 25%'
            WHEN tip_rate > 25 THEN 'More than 25%'
        END AS tip_category
    FROM filtered_trips
    WHERE tip_rate IS NOT NULL
),
trip_counts AS (
    SELECT
        borough,
        tip_category,
        COUNT(*) AS trip_count
    FROM categorized_trips
    GROUP BY borough, tip_category
),
total_trips AS (
    SELECT
        borough,
        SUM(trip_count) AS total_trips
    FROM trip_counts
    GROUP BY borough
)
SELECT 
    tc.borough, 
    tc.tip_category, 
    ROUND(tc.trip_count / t.total_trips, 4) AS proportion
FROM trip_counts AS tc
JOIN total_trips AS t
    ON tc.borough = t.borough
ORDER BY tc.borough, tc.tip_category;
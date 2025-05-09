WITH filtered_trips AS (
  SELECT 
    t.*,
    z.borough
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
    ON t.pickup_location_id = z.zone_id
  WHERE 
    DATE(t.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND LOWER(z.borough) NOT IN ('staten island', 'ewr')
    AND z.borough IS NOT NULL
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count > 0
    AND t.trip_distance >= 0
    AND t.fare_amount >= 0
    AND t.tip_amount >= 0
    AND t.tolls_amount >= 0
    AND t.mta_tax >= 0
    AND t.total_amount >= 0
    AND (t.total_amount - t.tip_amount) > 0
)
SELECT 
  borough, 
  tip_category, 
  ROUND(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (PARTITION BY borough), 4) AS proportion
FROM (
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
      ELSE NULL
    END AS tip_category
  FROM (
    SELECT 
      borough,
      SAFE_DIVIDE(tip_amount, (total_amount - tip_amount)) * 100 AS tip_rate
    FROM filtered_trips
  ) AS tip_calculations
  WHERE tip_rate IS NOT NULL
) AS tip_categories
WHERE tip_category IS NOT NULL
GROUP BY borough, tip_category
ORDER BY borough, tip_category;
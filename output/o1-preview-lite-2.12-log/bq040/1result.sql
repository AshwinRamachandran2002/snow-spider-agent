SELECT
  pickup_borough,
  tip_category,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough), 4) AS proportion
FROM (
  SELECT
    z.borough AS pickup_borough,
    CASE
      WHEN tip_rate = 0 THEN '0%'
      WHEN tip_rate > 0 AND tip_rate <= 5 THEN 'up to 5%'
      WHEN tip_rate > 5 AND tip_rate <= 10 THEN '5% to 10%'
      WHEN tip_rate > 10 AND tip_rate <= 15 THEN '10% to 15%'
      WHEN tip_rate > 15 AND tip_rate <= 20 THEN '15% to 20%'
      WHEN tip_rate > 20 AND tip_rate <= 25 THEN '20% to 25%'
      WHEN tip_rate > 25 THEN 'more than 25%'
    END AS tip_category
  FROM (
    SELECT
      t.*,
      CASE
        WHEN (total_amount - tip_amount) > 0 THEN (tip_amount / (total_amount - tip_amount)) * 100
        ELSE 0
      END AS tip_rate
    FROM
      `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
    WHERE
      DATE(t.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
      AND t.dropoff_datetime > t.pickup_datetime
      AND t.passenger_count > 0
      AND t.trip_distance >= 0
      AND t.tip_amount >= 0
      AND t.tolls_amount >= 0
      AND t.mta_tax >= 0
      AND t.fare_amount >= 0
      AND t.total_amount >= 0
      AND (total_amount - tip_amount) > 0
    ) AS filtered_trips
  JOIN
    `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
  ON
    filtered_trips.pickup_location_id = z.zone_id
  WHERE
    z.borough NOT IN ('EWR', 'Staten Island')
  ) AS trips_with_tip_category
GROUP BY
  pickup_borough,
  tip_category
ORDER BY
  pickup_borough,
  tip_category;
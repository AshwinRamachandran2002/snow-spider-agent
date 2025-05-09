WITH stats AS (
  SELECT
    z.borough,
    COUNT(*) AS total_trips,
    SUM(
      CASE
        WHEN (CASE WHEN y.total_amount = 0 
                   THEN 0 
                   ELSE (y.tip_amount * 100.0) / y.total_amount 
              END) = 0
        THEN 1 ELSE 0
      END
    ) AS no_tip_trips
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS z
    ON z.zone_id = y.pickup_location_id
  WHERE DATE(y.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND DATE(y.dropoff_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND y.dropoff_datetime > y.pickup_datetime          -- drop-off happens after pick-up
    AND y.passenger_count > 0
    AND y.trip_distance >= 0
    AND y.tip_amount   >= 0
    AND y.tolls_amount >= 0
    AND y.mta_tax      >= 0
    AND y.fare_amount  >= 0
    AND y.total_amount >= 0
  GROUP BY z.borough
)
SELECT
  borough,
  total_trips,
  no_tip_trips,
  ROUND(no_tip_trips * 100.0 / total_trips, 2) AS pct_no_tip
FROM stats
ORDER BY borough;
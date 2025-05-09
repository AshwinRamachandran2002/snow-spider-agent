-- Top‑10 most expensive yellow‑cab trips in NYC between 1 – 7 July 2016
SELECT
  p.zone_name                                                 AS pickup_zone,
  d.zone_name                                                 AS dropoff_zone,
  TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, SECOND)          AS trip_seconds,
  ROUND( SAFE_DIVIDE( CAST(y.trip_distance AS FLOAT64) ,
                      TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, SECOND) / 3600.0)
        , 2)                                                  AS speed_mph,
  ROUND( 100 * SAFE_DIVIDE(y.tip_amount, y.total_amount) , 2) AS tip_percent_of_total
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS p
       ON y.pickup_location_id  = p.zone_id
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS d
       ON y.dropoff_location_id = d.zone_id
WHERE DATE(y.pickup_datetime)  BETWEEN '2016-07-01' AND '2016-07-07'
  AND DATE(y.dropoff_datetime) BETWEEN '2016-07-01' AND '2016-07-07'
  AND y.dropoff_datetime  > y.pickup_datetime            -- ensure logical trip
  AND y.passenger_count   > 5                            -- more than five riders
  AND y.trip_distance     >= 10                         -- at least 10 miles
  -- exclude any negative fare‑related amounts
  AND y.fare_amount    >= 0
  AND y.mta_tax        >= 0
  AND y.tip_amount     >= 0
  AND y.tolls_amount   >= 0
  AND y.total_amount   >= 0
ORDER BY y.total_amount DESC
LIMIT 10;
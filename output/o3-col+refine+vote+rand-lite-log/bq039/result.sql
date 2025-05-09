-- Top-10 most expensive yellow-cab trips 1–7 July 2016 that satisfy all
-- stated constraints and show requested metrics
WITH eligible AS (
  SELECT
    t.*,
    TIMESTAMP_DIFF(t.dropoff_datetime , t.pickup_datetime , SECOND) AS trip_seconds
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE
        -- both pick-up and drop-off in 1 Jul ≤ time < 8 Jul 2016 (NYC local)
        t.pickup_datetime  BETWEEN '2016-07-01' AND '2016-07-08'
    AND t.dropoff_datetime BETWEEN '2016-07-01' AND '2016-07-08'
        -- logical time order
    AND t.dropoff_datetime > t.pickup_datetime
        -- ride / fare quality filters
    AND t.passenger_count > 5
    AND t.trip_distance   >= 10
    AND t.fare_amount     >= 0
    AND t.tip_amount      >= 0
    AND t.tolls_amount    >= 0
    AND t.mta_tax         >= 0
    AND t.total_amount    >= 0
)

SELECT
  p.zone_name AS pickup_zone,
  d.zone_name AS dropoff_zone,
  e.trip_seconds,
  ROUND( e.trip_distance / ( e.trip_seconds / 3600.0 ) , 2 )          AS mph,
  ROUND( 100 * e.tip_amount / NULLIF(e.total_amount , 0) , 2 )        AS tip_pct,
  e.total_amount
FROM   eligible AS e
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
       ON e.pickup_location_id = p.zone_id
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
       ON e.dropoff_location_id = d.zone_id
ORDER BY
  e.total_amount DESC
LIMIT 10;
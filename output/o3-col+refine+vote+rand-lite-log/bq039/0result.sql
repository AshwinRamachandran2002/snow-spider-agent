-- Top-10 most expensive large-party, long-distance yellow-cab trips
-- between 1 July 2016 and 7 July 2016 (inclusive)

SELECT
  p.zone_name                                                   AS pickup_zone ,
  d.zone_name                                                   AS dropoff_zone ,
  TIMESTAMP_DIFF(yt.dropoff_datetime , yt.pickup_datetime , SECOND)
                                                               AS trip_seconds ,
  yt.trip_distance ,
  SAFE_DIVIDE(
        yt.trip_distance ,
        TIMESTAMP_DIFF(yt.dropoff_datetime , yt.pickup_datetime , SECOND)/3600.0
  )                                                            AS mph ,
  SAFE_DIVIDE(yt.tip_amount , NULLIF(yt.total_amount , 0))*100 AS tip_pct ,
  yt.total_amount
FROM   `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS yt
JOIN   `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS p
  ON   yt.pickup_location_id  = p.zone_id
JOIN   `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS d
  ON   yt.dropoff_location_id = d.zone_id
WHERE  DATE(yt.pickup_datetime)  BETWEEN '2016-07-01' AND '2016-07-07'
  AND  DATE(yt.dropoff_datetime) BETWEEN '2016-07-01' AND '2016-07-07'
  AND  yt.passenger_count  > 5
  AND  yt.trip_distance    >= 10
  AND  yt.fare_amount      >= 0
  AND  yt.tip_amount       >= 0
  AND  yt.tolls_amount     >= 0
  AND  yt.mta_tax          >= 0
  AND  yt.total_amount     >= 0
  AND  yt.dropoff_datetime  > yt.pickup_datetime               -- logical trips only
ORDER BY yt.total_amount DESC
LIMIT  10 ;
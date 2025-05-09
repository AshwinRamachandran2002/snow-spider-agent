-- Top 10 high-passenger, long-distance yellow-cab trips
--   01 Jul 2016 00:00:00  →  07 Jul 2016 23:59:59  (i.e.  [2016-07-01, 2016-07-08) )
WITH qualified AS (
  SELECT
    t.pickup_datetime,
    t.dropoff_datetime,
    t.trip_distance,
    t.passenger_count,
    t.fare_amount,
    t.tip_amount,
    t.tolls_amount,
    t.mta_tax,
    t.total_amount,
    t.pickup_location_id,
    t.dropoff_location_id,
    -- trip duration in seconds
    TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) AS trip_seconds
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE
        -- calendar-day window 1 Jul → 7 Jul (half-open)
        t.pickup_datetime  >= '2016-07-01'
    AND t.pickup_datetime  <  '2016-07-08'
    AND t.dropoff_datetime >= '2016-07-01'
    AND t.dropoff_datetime <  '2016-07-08'

    -- temporal logic
    AND t.dropoff_datetime  >  t.pickup_datetime

    -- trip requirements
    AND t.passenger_count   >  5
    AND t.trip_distance     >= 10

    -- exclude negative money values
    AND t.fare_amount       >= 0
    AND t.tip_amount        >= 0
    AND t.tolls_amount      >= 0
    AND t.mta_tax           >= 0
    AND t.total_amount      >= 0
)

SELECT
  z_pick.zone_name                                              AS pickup_zone,
  z_drop.zone_name                                              AS dropoff_zone,
  q.trip_seconds                                                AS trip_duration_seconds,
  ROUND(q.trip_distance * 3600 / NULLIF(q.trip_seconds,0), 2)   AS speed_mph,
  ROUND(100 * q.tip_amount / NULLIF(q.total_amount,0), 2)       AS tip_rate_percent,
  q.total_amount                                                AS total_fare
FROM qualified AS q
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS z_pick
       ON z_pick.zone_id = q.pickup_location_id
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS z_drop
       ON z_drop.zone_id = q.dropoff_location_id
ORDER BY
  q.total_amount DESC
LIMIT 10;
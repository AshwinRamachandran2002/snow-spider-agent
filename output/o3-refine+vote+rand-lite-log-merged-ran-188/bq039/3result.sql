-- corrected query: join clauses moved before WHERE clause
SELECT
  COALESCE(p.zone_name, 'Unknown')  AS pickup_zone,
  COALESCE(d.zone_name, 'Unknown')  AS dropoff_zone,
  t.trip_seconds,
  ROUND(t.trip_distance / (t.trip_seconds / 3600), 2) AS speed_mph,
  ROUND(t.tip_amount / t.total_amount * 100, 2)       AS tip_rate_percent
FROM (
  -- combine 2016 yellow & green trips
  SELECT
    pickup_datetime,
    dropoff_datetime,
    CAST(passenger_count AS INT64)   AS passenger_count,
    CAST(trip_distance  AS FLOAT64)  AS trip_distance,
    CAST(total_amount   AS FLOAT64)  AS total_amount,
    CAST(tip_amount     AS FLOAT64)  AS tip_amount,
    CAST(tolls_amount   AS FLOAT64)  AS tolls_amount,
    CAST(mta_tax        AS FLOAT64)  AS mta_tax,
    CAST(fare_amount    AS FLOAT64)  AS fare_amount,
    CAST(extra          AS FLOAT64)  AS extra,
    CAST(imp_surcharge  AS FLOAT64)  AS imp_surcharge,
    CAST(pickup_location_id  AS STRING) AS pickup_loc,
    CAST(dropoff_location_id AS STRING) AS dropoff_loc,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) AS trip_seconds
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  
  UNION ALL
  
  SELECT
    pickup_datetime,
    dropoff_datetime,
    CAST(passenger_count AS INT64),
    CAST(trip_distance  AS FLOAT64),
    CAST(total_amount   AS FLOAT64),
    CAST(tip_amount     AS FLOAT64),
    CAST(tolls_amount   AS FLOAT64),
    CAST(mta_tax        AS FLOAT64),
    CAST(fare_amount    AS FLOAT64),
    CAST(extra          AS FLOAT64),
    CAST(imp_surcharge  AS FLOAT64),
    CAST(pickup_location_id  AS STRING),
    CAST(dropoff_location_id AS STRING),
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
) t
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` p
  ON t.pickup_loc = p.zone_id
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` d
  ON t.dropoff_loc = d.zone_id
WHERE
  t.pickup_datetime  BETWEEN TIMESTAMP('2016-07-01 00:00:00') AND TIMESTAMP('2016-07-07 23:59:59')
  AND t.dropoff_datetime BETWEEN TIMESTAMP('2016-07-01 00:00:00') AND TIMESTAMP('2016-07-07 23:59:59')
  AND t.dropoff_datetime > t.pickup_datetime
  AND t.passenger_count > 5
  AND t.trip_distance  >= 10
  AND t.trip_seconds   > 0
  AND t.total_amount   > 0
  AND t.tip_amount     >= 0
  AND t.tolls_amount   >= 0
  AND t.mta_tax        >= 0
  AND t.fare_amount    >= 0
  AND t.extra          >= 0
  AND t.imp_surcharge  >= 0
ORDER BY t.total_amount DESC
LIMIT 10;
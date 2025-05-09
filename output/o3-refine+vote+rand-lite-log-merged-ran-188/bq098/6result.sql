-- Percentage of yellow-cab trips with no tip (Jan 1-7 2016), by pickup borough
WITH eligible_trips AS (
  SELECT
    tz.borough,
    -- tip_rate = 0 if total_amount = 0 to avoid division by zero
    CASE
      WHEN t.total_amount > 0
        THEN (t.tip_amount * 100) / t.total_amount
      ELSE 0
    END AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`       AS tz
    ON t.pickup_location_id = tz.zone_id
  WHERE DATE(t.pickup_datetime)  BETWEEN '2016-01-01' AND '2016-01-07'
    AND DATE(t.dropoff_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count > 0
    AND t.trip_distance >= 0
    AND t.tip_amount    >= 0
    AND t.tolls_amount  >= 0
    AND t.mta_tax       >= 0
    AND t.fare_amount   >= 0
    AND t.total_amount  >= 0
)
SELECT
  borough,
  ROUND(100 * COUNTIF(tip_rate = 0) / COUNT(*), 2) AS percent_no_tip
FROM eligible_trips
GROUP BY borough
ORDER BY percent_no_tip DESC;
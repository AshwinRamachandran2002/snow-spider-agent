/* Percentage of yellow‑taxi trips (Jan 1–7 2016) with no tip, by pickup borough */
WITH cleaned_trips AS (
  SELECT
    tz.borough                                           AS pickup_borough,
    -- tip‑rate (%) – defined as 0 when total_amount = 0
    CASE
      WHEN t.total_amount > 0 THEN (t.tip_amount * 100) / t.total_amount
      ELSE 0
    END                                                  AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`          tz
    ON CAST(t.pickup_location_id AS STRING) = tz.zone_id
  WHERE
        -- require both pickup and drop‑off to be within 1–7 Jan 2016 (inclusive)
        t.pickup_datetime  BETWEEN '2016-01-01 00:00:00' AND '2016-01-07 23:59:59'
    AND t.dropoff_datetime BETWEEN '2016-01-01 00:00:00' AND '2016-01-07 23:59:59'
        -- drop‑off after pickup
    AND t.dropoff_datetime > t.pickup_datetime
        -- basic data‑quality filters
    AND t.passenger_count  > 0
    AND t.trip_distance    >= 0
    AND t.tip_amount       >= 0
    AND t.tolls_amount     >= 0
    AND t.mta_tax          >= 0
    AND t.fare_amount      >= 0
    AND t.total_amount     >= 0
)

SELECT
  pickup_borough                              AS borough,
  ROUND( 100 * SUM(CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END)
              / COUNT(*), 4)                  AS pct_no_tip
FROM cleaned_trips
GROUP BY borough
ORDER BY borough;
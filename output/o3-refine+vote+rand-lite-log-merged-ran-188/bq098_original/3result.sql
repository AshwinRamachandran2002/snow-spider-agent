WITH filtered_trips AS (
  SELECT
    t.pickup_datetime,
    t.dropoff_datetime,
    CAST(t.passenger_count AS INT64)         AS passenger_count,
    CAST(t.trip_distance  AS NUMERIC)        AS trip_distance,
    CAST(t.tip_amount     AS NUMERIC)        AS tip_amount,
    CAST(t.tolls_amount   AS NUMERIC)        AS tolls_amount,
    CAST(t.mta_tax        AS NUMERIC)        AS mta_tax,
    CAST(t.fare_amount    AS NUMERIC)        AS fare_amount,
    CAST(t.total_amount   AS NUMERIC)        AS total_amount,
    t.pickup_location_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE
        -- required date window (inclusive)
        DATE(t.pickup_datetime)  BETWEEN '2016-01-01' AND '2016-01-07'
    AND DATE(t.dropoff_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
        -- drop‑off must occur after pick‑up
    AND t.dropoff_datetime > t.pickup_datetime
        -- data‑quality filters
    AND t.passenger_count > 0
    AND CAST(t.trip_distance AS NUMERIC)  >= 0
    AND CAST(t.tip_amount    AS NUMERIC)  >= 0
    AND CAST(t.tolls_amount  AS NUMERIC)  >= 0
    AND CAST(t.mta_tax       AS NUMERIC)  >= 0
    AND CAST(t.fare_amount   AS NUMERIC)  >= 0
    AND CAST(t.total_amount  AS NUMERIC)  >= 0
),
trips_with_borough AS (
  SELECT
    z.borough                                                   AS pickup_borough,
    -- tip rate (percentage).  If total_amount = 0, treat as 0 tip rate.
    CASE
      WHEN total_amount = 0 THEN 0
      ELSE SAFE_DIVIDE(tip_amount * 100, total_amount)
    END                                                        AS tip_rate
  FROM filtered_trips  f
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
    ON f.pickup_location_id = z.zone_id
)
SELECT
  pickup_borough,
  ROUND( 100 * SUM(CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END) / COUNT(*), 4 ) AS pct_no_tip
FROM trips_with_borough
GROUP BY pickup_borough
ORDER BY pickup_borough;